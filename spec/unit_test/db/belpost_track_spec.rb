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
    end

    it 'should receive data for valid track' do
      track = FactoryBot.create :track, number: 'EA009030735BY'
      expect { track.__send__(:load_message) }.not_to raise_error

      expect(track.message.split("\n").size).to eq 12
      expect(track.message.split("\n").first).to eq '<b>EA009030735BY</b>'
      expect(track.message.split("\n").last).to include '14:19:00'
    end

    it 'should process error response from server' do
      track = FactoryBot.create :track, number: 'EA009030736BY'
      expect { track.__send__(:load_message) }.not_to raise_error

      expect(track.message).to be_empty
    end
  end
end
