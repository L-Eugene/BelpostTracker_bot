# frozen_string_literal: true

# Migrate #2
class AddCommentToLinks < ActiveRecord::Migration[5.0]
  def self.up
    add_column :links, :comment, :string
  end

  def self.down
    remove_column :links, :comment
  end
end
