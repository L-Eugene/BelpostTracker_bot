# frozen_string_literal: true

describe Belpost::Chat do
  let(:chat)  { FactoryBot.create :chat }
  let(:track) { FactoryBot.create :track }

  describe '#full?' do
    it 'should be false for empty chat' do
      chat.inspect
      expect(chat.full?).to be_falsey
    end

    it 'should be true for full chat' do
      Belpost::Chat::TRACK_LIMIT.times { chat.add FactoryBot.create :track }

      expect(chat.full?).to be_truthy
    end
  end

  describe '#add' do
    it 'shouldn\'t raise on belpost track' do
      expect { chat.add track }.not_to raise_error
    end

    it 'shouldn\'t raise on evropochta track' do
      expect { chat.add FactoryBot.create(:track, number: 'BY080013281922') }.not_to raise_error
    end

    it 'should raise on invalid track numbers' do
      %w[AZ080013281922 SB07473480LV BY80013281922].each do |num|
        expect { chat.add FactoryBot.create(:track, number: num) }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    it 'should raise on duplicate track' do
      expect { chat.add track }.not_to raise_error
      expect { chat.add track }.to raise_error(Belpost::Error)
    end

    it 'should raise on #add if chat is full' do
      Belpost::Chat::TRACK_LIMIT.times { chat.add FactoryBot.create :track }

      expect { chat.add track }.to raise_error(Belpost::Error)
    end
  end

  describe '#watching?' do
    before :each do
      chat.add FactoryBot.create :track
      chat.add track
      chat.add FactoryBot.create :track
    end

    it 'should return true for valid watched track' do
      expect(chat.__send__(:watching?, track)).to be_truthy
    end

    it 'should return false for valid unwatched track' do
      expect(chat.__send__(:watching?, FactoryBot.create(:track))).to be_falsey
    end

    it 'should return false for invalid track' do
      expect(chat.__send__(:watching?, FactoryBot.create(:track))).to be_falsey
    end

    it 'should return false for nil object' do
      expect(chat.__send__(:watching?, nil)).to be_falsey
    end
  end

  describe '#unwatch' do
    before :each do
      chat.add track
    end

    it 'should remove watched track' do
      expect { chat.unwatch track }.not_to raise_error
      expect(chat.tracks.size).to be_zero
    end

    it 'should remove watched track' do
      expect { chat.unwatch FactoryBot.create(:track) }.to raise_error(Belpost::Error)
      expect(chat.tracks.size).to be 1
    end
  end
end
