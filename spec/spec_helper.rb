require 'openaiext'
require 'rspec'
require 'webmock/rspec'
require 'json'

# Disable external HTTP requests
WebMock.disable_net_connect!(allow_localhost: true)

# Helper module for test mocks
module OpenAIExtHelpers
  # Create a mock OpenAI API client response
  def mock_openai_response(content: nil, function_calls: nil, model: 'gpt-4')
    response = {
      'id' => "chatcmpl-#{SecureRandom.hex(6)}",
      'object' => 'chat.completion',
      'created' => Time.now.to_i,
      'model' => model,
      'choices' => [
        {
          'index' => 0,
          'message' => {
            'role' => 'assistant'
          },
          'finish_reason' => content.nil? && function_calls ? 'tool_calls' : 'stop'
        }
      ],
      'usage' => {
        'prompt_tokens' => 50,
        'completion_tokens' => 20,
        'total_tokens' => 70
      }
    }

    # Add content if provided
    response['choices'][0]['message']['content'] = content if content

    # Add function calls if provided
    if function_calls
      response['choices'][0]['message']['tool_calls'] = function_calls.map.with_index do |func, idx|
        {
          'id' => "call_#{SecureRandom.hex(6)}",
          'type' => 'function',
          'function' => {
            'name' => func[:name],
            'arguments' => func[:arguments].is_a?(String) ? func[:arguments] : JSON.generate(func[:arguments])
          }
        }
      end
    end

    response
  end

  # Mock the OpenAI API client
  def stub_openai_client
    client = instance_double(OpenAI::Client)
    allow(OpenAI::Client).to receive(:new).and_return(client)
    client
  end
end

RSpec.configure do |config|
  # Include helper methods
  config.include OpenAIExtHelpers

  # Basic configuration
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  # Shared context setup
  config.shared_context_metadata_behavior = :apply_to_host_groups
  
  # Focus filtering
  config.filter_run_when_matching :focus
  
  # Use proper syntax
  config.disable_monkey_patching!
  
  # Show warnings
  config.warnings = true

  # Use document formatter for single specs
  if config.files_to_run.one?
    config.default_formatter = "doc"
  end

  # Randomize test order
  config.order = :random
  Kernel.srand config.seed
  
  # Clear mocks before each test
  config.before(:each) do
    # Reset WebMock
    WebMock.reset!
  end
end