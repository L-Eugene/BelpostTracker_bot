# frozen_string_literal: true

describe Belpost::Chat do
  before :each do
    @chat = FactoryBot.create(:chat)
  end

  describe '#full?' do
    context 'empty chat' do
      it 'should be false' do
        @chat.inspect
        expect(@chat.full?).to be_falsey
      end
    end

    context 'full chat' do
      it 'should be true' do
        Belpost::Chat::TRACK_LIMIT.times { @chat.add FactoryBot.create :track }

        expect(@chat.full?).to be_truthy
      end
    end
  end

  describe '#add' do
    context 'empty chat' do
      it 'shouldn\'t raise on new track' do
        track = FactoryBot.create :track
        expect { @chat.add track }.not_to raise_error
      end

      it 'should raise on duplicate track' do
        track = FactoryBot.create :track
        expect { @chat.add track }.not_to raise_error
        expect { @chat.add track }.to raise_error(Belpost::Error)
      end
    end

    context 'full chat' do
      it 'should raise on #add' do
        Belpost::Chat::TRACK_LIMIT.times { @chat.add FactoryBot.create :track }

        track = FactoryBot.create :track
        expect { @chat.add track }.to raise_error(Belpost::Error)
      end
    end
  end

  describe '#watching?' do
    before(:each) do
      @track = FactoryBot.create :track

      @chat.add FactoryBot.create :track
      @chat.add @track
      @chat.add FactoryBot.create :track
    end

    it 'should return true for valid track' do
      expect(@chat.__send__(:watching?, @track)).to be_truthy
    end

    it 'should return false for invalid track' do
      expect(@chat.__send__(:watching?, FactoryBot.create(:track))).to be_falsey
    end

    it 'should return false for nil object' do
      expect(@chat.__send__(:watching?, nil)).to be_falsey
    end
  end
end
