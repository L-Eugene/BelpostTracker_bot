# frozen_string_literal: true

# Migrate #2
class ChangeDataTypeForMd5 < ActiveRecord::Migration
  def self.up
    change_table :tracks do |t|
      t.change :md5, :string
    end
  end

  def self.down
    change_table :tracks do |t|
      t.change :md5, :integer
    end
  end
end
