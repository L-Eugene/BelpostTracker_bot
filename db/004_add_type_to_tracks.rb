# frozen_string_literal: true

# Migrate #4
class AddTypeToTracks < ActiveRecord::Migration[6.1]
  def self.up
    add_column :tracks, :type, :string

    Belpost::Track.all.each do |track|
      execute <<~SQL
        UPDATE tracks
        SET
          type='#{Belpost::Track.descendants.detect { |k| k::REGEX === track.number }}'
        WHERE
          number = '#{track.number}';
      SQL
    end
  end

  def self.down
    remove_column :tracks, :type
  end
end
