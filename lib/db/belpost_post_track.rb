# frozen_string_literal: true

module Belpost
  # Class for regular post track numbers
  class PostTrack < Track
    REGEX = %r{[A-Z]{2}\d{9}[A-Z]{2}}.freeze

    validates_format_of :number, with: REGEX, on: :create

    def api_get
      conn = Faraday.new 'https://api.belpost.by/api/v1/tracking', ssl: { verify: false }

      hash = JSON.parse(conn.post('', number: number).body, symbolize_names: true)

      (hash[:data] || [{ steps: [] }]).first[:steps].map do |step|
        "<b>#{step[:created_at]}</b>: #{step[:event]} <i>#{step[:place]}</i>"
      end.reverse.join("\n")
    rescue JSON::ParserError => e
      Belpost.log.error "#{number} data is invalid: #{e.message}\n#{data}"
      ''
    ensure
      # Need to sleep for 1 minute to avoid block from API
      sleep 1.minute unless ENV.key?('DO_NOT_SLEEP')
    end
  end
end
