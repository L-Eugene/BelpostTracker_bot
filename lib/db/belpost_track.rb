module Belpost

  class Track < BelpostBase
    has_many :links
    has_many :chats, through: :links

    validates_format_of :number, with: %r([A-Z]{2}\d{9}[A-Z]{2}), on: :create

    def watched?
      chats.any?(&:enabled?)
    end
  end
end
