# frozen_string_literal: true

require 'active_record'
require 'log/belpost_logger'

# Belpost module
module Belpost
  # default ActiveRecord class
  class BelpostBase < ActiveRecord::Base
    self.abstract_class = true

    establish_connection(Belpost::Config.instance.options['database'])
    @logger = Belpost.log
  end

  ActiveSupport::LogSubscriber.colorize_logging = false
end

require 'db/belpost_chat.rb'
require 'db/belpost_track.rb'
require 'db/belpost_link.rb'
