# frozen_string_literal: true

# Migrate #1
class CreateDatabase < ActiveRecord::Migration
  def create_chats
    create_table :chats do |t|
      t.string :chat_id
      t.boolean :enabled
    end
  end

  def create_tracks
    create_table :tracks do |t|
      t.string :number
      t.integer :md5
      t.text :message

      t.timestamps null: false
    end
  end

  def create_links
    create_table :links do |t|
      t.belongs_to :chat, index: true
      t.belongs_to :track, index: true
    end
  end

  def self.up
    create_chats
    create_tracks
    create_links
  end

  def self.down
    drop_table :chats
    drop_table :tracks
    drop_table :links
  end
end
