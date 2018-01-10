# frozen_string_literal: true

module Belpost
  # Link between track and chat
  class Link < BelpostBase
    belongs_to :chat
    belongs_to :track
  end
end
