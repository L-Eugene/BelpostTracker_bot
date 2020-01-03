# frozen_string_literal: true

require 'telegram/bot'
require 'singleton'
require 'yaml'

module Belpost
  # Configuration singleton
  class Config
    include Singleton

    attr_reader :options

    CONFIG_PATH = "#{__FILE__}.yml"

    def initialize
      @options = YAML.load_file(CONFIG_PATH)
    end
  end
end

$LOAD_PATH.unshift(
  File.join(File.dirname(__FILE__), Belpost::Config.instance.options['libdir'])
)

require 'db/belpost_model'
require 'log/belpost_logger'
require 'belpost_classes'

# Main Bot Class
class BelpostTrackerBot
  attr_reader :client, :chat

  def initialize
    @client = Belpost.telegram
  end

  def update_message(message)
    @chat = Belpost::Chat.find_or_create_by(chat_id: message.chat.id)

    meth = method_from_message(message.text)
    send(meth, message.text) if respond_to? meth.to_sym, true
  end

  def update_cq(cbq)
    @chat = Belpost::Chat.find_or_create_by(chat_id: cbq.message.chat.id)

    meth = method_from_message(cbq.data, 'callback')
    send(meth, cbq) if respond_to? meth.to_sym, true
  end

  def update(data)
    update = Telegram::Bot::Types::Update.new(data)

    update_message update.message unless update.message.nil?
    update_cq update.callback_query unless update.callback_query.nil?
  end

  def scan
    Belpost.log.info 'Starting scan'

    update_tracks
    drop_old_tracks

    Belpost.log.info 'Finish scan'
  end

  private

  HELP_MESSAGE = <<~TEXT
    */help* - Вывести это сообщение
    */list* - Список наблюдаемых в этом чате трек-номеров
    */add* _track_ _comment_ - Добавить трек-номер в список наблюдаемых
    */delete* _track_ - Удалить трек-номер из списка наблюдаемых
  TEXT

  def update_tracks
    Belpost::Track.find_each do |t|
      Belpost.log.info "Scanning #{t.number}"
      t.refresh if t.watched?
    end
  end

  def method_from_message(text, prefix = 'cmd')
    meth = (text || '').downcase.tr('_', ' ')
    [%r{\@.*$}, %r{\s.*$}, %r{^/}].each { |x| meth.gsub!(x, '') }

    Belpost.log.info "#{meth} command from #{chat.chat_id}"
    Belpost.log.debug "Full command is #{text}"

    "#{prefix}_#{meth}"
  end

  def cmd_add(text)
    num = text.gsub(%r{/add[\s_]*}, '').split(%r{\s})
    track = Belpost::Track.find_or_create_by(number: num.shift.upcase)

    chat.add track, num.join(' ')
    chat.send_text 'Трек-номер добавлен в список наблюдаемых'
  rescue StandardError
    log_exception $ERROR_INFO
  end

  def cmd_delete(text, quiet = false)
    num = text.gsub(%r{/delete\s*}, '')
    track = Belpost::Track.find_by(number: num)

    chat.unwatch track
    chat.send_text 'Трек-номер удален из списка наблюдаемых' unless quiet
  rescue StandardError
    log_exception $ERROR_INFO
  end

  def cmd_list(_)
    chat.send_text chat.status, 'HTML', chat.list_keyboard
  end

  def cmd_help(_)
    chat.send_text HELP_MESSAGE
  end

  def callback_show(query)
    chat.show_track(query.message.message_id, query.data.gsub(%r{show\s+}, ''))
  end

  def callback_list(query)
    chat.delete_message(query.message.message_id)
    cmd_list(query.data)
  end

  def callback_delete(query)
    cmd_delete("/#{query.data}", true)
    chat.delete_message(query.message.message_id)
    cmd_list(query.data)
  end

  def log_exception(error)
    Belpost.log.error error
    respond = error.respond_to? 'to_chat'
    chat.send_text respond ? error.to_chat : 'Некорректный трек-номер'
  end

  def drop_old_tracks
    cond = 'updated_at < DATE_SUB(NOW(), INTERVAL 4 MONTH)'
    Belpost::Track.where(cond).find_each do |t|
      t.chats.where(enabled: true).each do |c|
        c.send_text <<~MSG
          Номер #{t.number} давно не обновлялся, удаляю из списка наблюдения
          Если Вы хотите продолжить наблюдать за этим номером, добавьте его с помощью команды /add_#{t.number}
        MSG
      end
      t.destroy
    end
  end
end
