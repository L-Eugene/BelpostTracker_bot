# frozen_string_literal: true

require 'db/belpost_track'

FactoryBot.define do
  factory :track, class: Belpost::Track do
    number do
      String.new.tap do |str|
        2.times {str << [*'A'..'Z'].sample }
        9.times {str << [*'1'..'9'].sample }
        2.times {str << [*'A'..'Z'].sample }
      end
    end
  end
end