# frozen_string_literal: true

describe '/add command' do
  let(:chat)     { FactoryBot.create :chat }
  let(:bot)      { BelpostTrackerBot.new.tap { |obj| obj.instance_variable_set(:@chat, chat) } }
  let(:bot_url)  { 'https://api.telegram.org/botsometoken/sendMessage' }
  let(:messages) do
    {
      success: 'Трек-номер добавлен в список наблюдаемых',
      failure: 'Некорректный трек-номер'
    }
  end

  before :each do
    stub_request(:post, bot_url).to_return(status: 200, body: '', headers: {})
  end

  it 'should add BelPost track number' do
    bot.__send__(:cmd_add, '/add EA009030735BY')

    expect(WebMock).to(have_requested(:post, bot_url).with { |req| CGI.unescape(req.body).include? messages[:success] })
  end

  it 'should add Evropochta track number' do
    bot.__send__(:cmd_add, '/add BY080013226247')

    expect(WebMock).to(have_requested(:post, bot_url).with { |req| CGI.unescape(req.body).include? messages[:success] })
  end

  it 'should not add invalid track number' do
    bot.__send__(:cmd_add, '/add EA0090305735BY')

    expect(WebMock).to(have_requested(:post, bot_url).with { |req| CGI.unescape(req.body).include? messages[:failure] })
  end
end
