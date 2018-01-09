#
# file: belposttrackerbot.rb 
#
require 'telegram/bot'
require 'singleton'
require 'yaml'

module Belpost
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
    Belpost::Track.find_each do |t| 
      t.refresh if t.watched?
    end
  end

  private

  HELP_MESSAGE = <<~TEXT
    */help* - print this help message
    */list* - list tracknumbers watched in this chat
    */add* _track_ - add tracknumber to watchlist
    */delete* _track_ - delete tracknumber from watchlist
  TEXT

  def method_from_message(text)
    meth = (text || '').downcase
    [%r{\@.*$}, %r{\s.*$}, %r{^/}].each { |x| meth.gsub!(x, '') }

    log.info "#{meth} command from #{chat.chat_id}"
    log.debug "Full command is #{text}"

    "cmd_#{meth}"
  end

  def cmd_add(text)
    num = text.gsub(%r{/add\s*}, '')
    track = Belpost::Track.find_or_create_by(number: num)

    chat.add track
    chat.send_text 'Added track to this chat list'
  rescue Belpost::Error
    chat.send_text $ERROR_INFO.to_chat if $ERROR_INFO.respond_to? 'to_chat'
    log.error $ERROR_INFO
  rescue StandardError
    chat.send_text 'Invalid track number'
    log.error $ERROR_INFO
  end

  def cmd_delete(text)
    num = text.gsub(%r{/delete\s*}, '')
    track = Belpost::Track.find_by(number: num)

    chat.unwatch track
    chat.send_text 'Removed track number from watch list'
  rescue Belpost::Error
    chat.send_text $ERROR_INFO.to_chat if $ERROR_INFO.respond_to? 'to_chat'
    log.error $ERROR_INFO
  rescue StandardError
    chat.send_text 'Invalid track number'
    log.error $ERROR_INFO
  end

  def cmd_list(_)
    chat.send_text chat.list, 'HTML'
  end

  def cmd_help(_)
    chat.send_text HELP_MESSAGE
  end
end
