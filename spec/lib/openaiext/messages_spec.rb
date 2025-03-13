require 'spec_helper'
require 'openaiext/messages'

RSpec.describe OpenAIExt::Messages do
  describe '#initialize' do
    it 'creates an empty messages array when nil is passed' do
      messages = OpenAIExt::Messages.new(nil)
      expect(messages).to be_empty
    end
    
    it 'properly formats a standard message with symbol keys' do
      messages = OpenAIExt::Messages.new([{ role: :user, content: 'Hello' }])
      expect(messages.first).to eq({ role: 'user', content: 'Hello' })
    end
    
    it 'properly formats a standard message with string keys' do
      messages = OpenAIExt::Messages.new([{ 'role' => 'user', 'content' => 'Hello' }])
      expect(messages.first).to eq({ role: 'user', content: 'Hello' })
    end
    
    it 'handles simplified single key format' do
      messages = OpenAIExt::Messages.new([{ user: 'Hello' }])
      expect(messages.first).to eq({ role: 'user', content: 'Hello' })
    end
    
    it 'processes array of messages' do
      input = [
        { system: 'You are a helpful assistant' },
        { user: 'Hello' }
      ]
      messages = OpenAIExt::Messages.new(input)
      expect(messages.length).to eq 2
      expect(messages[0]).to eq({ role: 'system', content: 'You are a helpful assistant' })
      expect(messages[1]).to eq({ role: 'user', content: 'Hello' })
    end
    
    it 'handles complex content with arrays' do
      input = [{
        role: 'user',
        content: [
          { type: 'text', text: 'What is this image?' },
          { type: 'image_url', image_url: { url: 'https://example.com/image.jpg' } }
        ]
      }]
      messages = OpenAIExt::Messages.new(input)
      expect(messages.first[:content].length).to eq 2
      expect(messages.first[:content][0]['type']).to eq 'text'
      expect(messages.first[:content][1]['type']).to eq 'image_url'
    end
    
    it 'raises an error for invalid role' do
      expect {
        OpenAIExt::Messages.new([{ invalid_role: 'Hello' }])
      }.to raise_error(ArgumentError, /Invalid role/)
    end
  end
  
  describe '#add' do
    it 'adds a new message to existing messages' do
      messages = OpenAIExt::Messages.new([{ user: 'Hello' }])
      messages.add({ assistant: 'Hi there' })
      expect(messages.length).to eq 2
      expect(messages[1]).to eq({ role: 'assistant', content: 'Hi there' })
    end
  end
end