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
  attr_reader :client, :log, :chat

  def initialize
    @client = Belpost::Tlg.instance
    @log = Belpost::Log.instance
  end

  def update(data)
    update = Telegram::Bot::Types::Update.new(data)
    message = update.message

    return if message.nil?

    @chat = Belpost::Chat.find_or_create_by(chat_id: message.chat.id)

    meth = method_from_message(message.text)

    send(meth, message.text) if respond_to? meth.to_sym, true
  end

  def scan
    return log.warn 'Previous scan is still running.' if scanning?
    scan_flag

    update_tracks
    drop_old_tracks

    scan_unflag
  end

  private

  HELP_MESSAGE = <<~TEXT
    */help* - print this help message
    */list* - list tracknumbers watched in this chat
    */add* _track_ - add tracknumber to watchlist
    */delete* _track_ - delete tracknumber from watchlist
  TEXT

  def scanning?
    File.exist? Belpost::Config.instance.options['flag']
  end

  def scan_flag
    log.info 'Starting scan'
    FileUtils.touch Belpost::Config.instance.options['flag']
  end

  def scan_unflag
    FileUtils.rm Belpost::Config.instance.options['flag']
    log.info 'Finish scan'
  end

  def update_tracks
    Belpost::Track.find_each do |t|
      log.info "Scanning #{t.number}"
      t.refresh if t.watched?
    end
  end

  def method_from_message(text)
    meth = (text || '').downcase
    [%r{\@.*$}, %r{\s.*$}, %r{^/}].each { |x| meth.gsub!(x, '') }

    log.info "#{meth} command from #{chat.chat_id}"
    log.debug "Full command is #{text}"

    "cmd_#{meth}"
  end

  def cmd_add(text)
    num = text.gsub(%r{/add\s*}, '').split(%r{\s})
    track = Belpost::Track.find_or_create_by(number: num.shift)

    chat.add track, num.join(' ')
    chat.send_text 'Added track to this chat list'
  rescue StandardError
    log.error $ERROR_INFO
    respond = $ERROR_INFO.respond_to? 'to_chat'
    chat.send_text respond ? $ERROR_INFO.to_chat : 'Invalid track number'
  end

  def cmd_delete(text)
    num = text.gsub(%r{/delete\s*}, '')
    track = Belpost::Track.find_by(number: num)

    chat.unwatch track
    chat.send_text 'Removed track number from watch list'
  rescue StandardError
    log.error $ERROR_INFO
    respond = $ERROR_INFO.respond_to? 'to_chat'
    chat.send_text respond ? $ERROR_INFO.to_chat : 'Invalid track number'
  end

  def cmd_list(_)
    chat.send_text chat.list, 'HTML'
  end

  def cmd_help(_)
    chat.send_text HELP_MESSAGE
  end

  def drop_old_tracks
    cond = 'updated_at < DATE_SUB(NOW(), INTERVAL 4 MONTH)'
    Belpost::Track.where(cond).find_each do |t|
      t.chats.each do |c|
        msg = <<~MSG
          #{t.number} was not updated for too long, removing it from watchlist
          If you still want to watch it, add it again with /add #{t.number}
        MSG
        c.send_text msg if c.enabled?
      end
      t.destroy
    end
  end
end
