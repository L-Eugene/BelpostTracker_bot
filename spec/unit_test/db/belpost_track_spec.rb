# frozen_string_literal: true

describe Belpost::Track do
  let(:track) { FactoryBot.create :track }

  describe '#watched?' do
    let(:chat) { FactoryBot.create :chat }

    it 'should return true if watched by active chat' do
      chat.add track
      expect(track.watched?).to be_truthy
    end

    it 'should return false if watched by inactive chat' do
      chat.add track
      chat.update_attribute(:enabled, false)

      expect(track.watched?).to be_falsey
    end

    it 'should return if not watched by chat' do
      expect(track.watched?).to be_falsey
    end
  end

  describe '#load_message' do
    before :each do
      %w[EA009030735BY EA009030736BY].each do |track|
        stub_request(:post, 'https://api.belpost.by/api/v1/tracking')
          .with(
            body: { 'number' => track }
          )
          .to_return(
            YAML.load_file(File.join(FIXTURES_PATH, 'tracks', "#{track}.yml"))
          )
      end

      %w[BY080013226247].each do |track|
        stub_request(:get, "https://evropochta.by/api/track.json/?number=#{track}")
          .to_return(
            YAML.load_file(File.join(FIXTURES_PATH, 'tracks', "#{track}.yml"))
          )
      end
    end

    it 'should receive data for belpost track' do
      track = FactoryBot.create :track, number: 'EA009030735BY'
      expect { track.__send__(:load_message) }.not_to raise_error

      expect(track.message.split("\n").size).to eq 12
      expect(track.message.split("\n").first).to eq '<b>EA009030735BY</b>'
      expect(track.message.split("\n").last).to include '14:19:00'
    end

    it 'should receive data for evropochta track' do
      track = FactoryBot.create :track, number: 'BY080013226247'
      expect { track.__send__(:load_message) }.not_to raise_error

      expect(track.message.split("\n").size).to eq 10
      expect(track.message.split("\n").first).to eq '<b>BY080013226247</b>'
      expect(track.message.split("\n").last).to include '20:28:47'
    end

    it 'should process error response from server' do
      track = FactoryBot.create :track, number: 'EA009030736BY'
      expect { track.__send__(:load_message) }.not_to raise_error

      expect(track.message).to be_empty
    end
  end

  describe '#find_or_create_by_number' do
    let(:old_tracks) { %w[EA009030736BY BY080013226247] }
    let(:new_tracks) { %w[EA009030737BY BY080013226248] }
    let(:bad_tracks) { %w[EA0090030737BY AZ080013226248] }

    before :each do
      old_tracks.each { |num| FactoryBot.create :track, number: num }
    end

    it 'should not create new track for existing number' do
      old_tracks.each do |num|
        track = Belpost::Track.find_or_create_by_number(num)
        expect(track).to be_a(Belpost::Track)
        expect(Belpost::Track.all.size).to eq old_tracks.size
      end
    end

    it 'should create new objects' do
      new_tracks.each_with_index do |num, i|
        track = Belpost::Track.find_or_create_by_number(num)
        expect(track).to be_a(Belpost::Track)
        expect(track.persisted?).to be_truthy
        expect(track.errors).to be_empty
        expect(Belpost::Track.all.size).to eq old_tracks.size + i + 1
      end
    end

    it 'should raise an exception for invalid tracks' do
      bad_tracks.each do |num|
        track = Belpost::Track.find_or_create_by_number(num)
        expect(track.persisted?).to be_falsey
        expect(track.errors).not_to be_empty
      end
    end
  end
end
