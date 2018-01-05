module Belpost
  class Link < BelpostBase
    belongs_to :chat
    belongs_to :track
  end
end
