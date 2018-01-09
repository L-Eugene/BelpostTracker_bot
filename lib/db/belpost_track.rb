require 'nokogiri'
require 'digest'

module Belpost

  class Track < BelpostBase
    has_many :links
    has_many :chats, through: :links

    validates_format_of :number, with: %r([A-Z]{2}\d{9}[A-Z]{2}), on: :create

    def watched?
      chats.any?(&:enabled?)
    end

    def refresh
      url = "https://webservices.belpost.by/searchRu/#{number}"
      msg = "<b>#{number}</b>\n#{parse Faraday.get(url).body}"
      digest = Digest::MD5.hexdigest msg


      if md5 != digest
        self.md5 = digest
        self.message = msg
        chats.each do |c| 
          c.send_text(msg, 'HTML') if c.enabled?
        end
        save
      end
    end

    private

    def parse(html)
      result = []

      Nokogiri::HTML(html).css('#Panel2 table tr').each do |tr|
        next if (date = tr.css('td[1]').text).empty?
        status = cleanup tr.css('td[2]').text
        place = cleanup tr.css('td[3]').text, true
        date.gsub!(%r{(\d{2})\.(\d{2})\.(\d{4})}, '\3-\2-\1')
        result << "<b>#{date}</b>: #{status} <i>#{place}</i>"
      end

      result.join "\n"
    end

    private

    def cleanup(text, brackets = false)
      result = text.gsub(/^\s*/, '').gsub(/\s*$/, '')
      (brackets && !result.empty?) ? "(#{result})" : result
    end
  end
end
