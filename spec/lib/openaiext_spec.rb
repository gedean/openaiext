require 'spec_helper'

RSpec.describe OpenAIExt do
  describe '.load_config' do
    it 'configures the OpenAI client' do
      # Store original values
      original_access_token = ENV['OPENAI_ACCESS_TOKEN']
      original_org_id = ENV['OPENAI_ORGANIZATION_ID']
      
      # Set test values
      ENV['OPENAI_ACCESS_TOKEN'] = 'test-token'
      ENV['OPENAI_ORGANIZATION_ID'] = 'test-org'
      
      # Mock OpenAI configuration
      config = double('OpenAI::Configuration')
      
      allow(config).to receive(:access_token=)
      allow(config).to receive(:organization_id=)
      allow(config).to receive(:request_timeout=)
      allow(config).to receive(:log_errors=)
      
      allow(OpenAI).to receive(:configure).and_yield(config)
      
      # Run the method
      OpenAIExt.load_config
      
      # Verify configuration
      expect(config).to have_received(:access_token=).with('test-token')
      expect(config).to have_received(:organization_id=).with('test-org')
      expect(config).to have_received(:request_timeout=).with(300)
      expect(config).to have_received(:log_errors=).with(true)
      
      # Restore original values
      ENV['OPENAI_ACCESS_TOKEN'] = original_access_token
      ENV['OPENAI_ORGANIZATION_ID'] = original_org_id
    end
  end

  describe '.single_prompt' do
    it 'delegates to chat with correctly formatted messages' do
      expect(OpenAIExt).to receive(:chat).with(
        messages: [{ role: :user, content: 'Hello' }],
        model: :gpt_basic,
        response_format: nil,
        max_tokens: OpenAIExt::MAX_TOKENS,
        store: true,
        tools: nil,
        auto_run_functions: false,
        function_context: nil,
        temperature: nil,
        top_p: nil,
        frequency_penalty: nil,
        presence_penalty: nil,
        prediction: nil
      )
      
      OpenAIExt.single_prompt(prompt: 'Hello')
    end
  end

  describe '.single_chat' do
    it 'delegates to chat with system and user messages' do
      expect(OpenAIExt).to receive(:chat).with(
        messages: [
          { role: :system, content: 'You are a helpful assistant' },
          { role: :user, content: 'Hello' }
        ],
        model: :gpt_basic,
        response_format: nil,
        max_tokens: OpenAIExt::MAX_TOKENS,
        store: true,
        tools: nil,
        auto_run_functions: false,
        function_context: nil,
        temperature: nil,
        top_p: nil,
        frequency_penalty: nil,
        presence_penalty: nil,
        prediction: nil
      )
      
      OpenAIExt.single_chat(system: 'You are a helpful assistant', user: 'Hello')
    end
  end

  describe '.vision' do
    it 'formats vision API requests correctly' do
      expect(OpenAIExt).to receive(:chat).with(
        messages: [
          {
            role: :user,
            content: [
              { type: :text, text: 'Describe this image' },
              { type: :image_url, image_url: { url: 'https://example.com/img.jpg' } }
            ]
          }
        ],
        model: :gpt_advanced,
        response_format: nil,
        max_tokens: OpenAIExt::MAX_TOKENS,
        store: true,
        tools: nil,
        auto_run_functions: false,
        function_context: nil
      )
      
      OpenAIExt.vision(
        prompt: 'Describe this image',
        image_url: 'https://example.com/img.jpg'
      )
    end
  end
end