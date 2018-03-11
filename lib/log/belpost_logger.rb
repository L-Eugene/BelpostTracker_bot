# frozen_string_literal: true

require 'singleton'

# Belpost module
module Belpost
  # Logger singleton
  class Log < Logger
    include Singleton

    def initialize
      super Belpost::Config.instance.options['logfile'], 'daily'
      flag = Belpost::Config.instance.options['debug']

      self.level = Logger::INFO
      self.level = Logger::DEBUG if File.exist?(flag)
      self.formatter = proc do |severity, datetime, _progname, msg|
        date_format = datetime.strftime('%Y-%m-%d %H:%M:%S')
        "[#{date_format}] #{severity}: #{msg}\n"
      end
    end
  end

  # Get instance of Logger
  def self.log
    Belpost::Log.instance
  end
end
