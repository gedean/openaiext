require 'spec_helper'
require 'openaiext/response_extender'

RSpec.describe ResponseExtender do
  let(:basic_response) do
    {
      'id' => 'chatcmpl-123',
      'model' => 'gpt-4',
      'choices' => [
        {
          'message' => {
            'role' => 'assistant',
            'content' => 'Hello, how can I help you?'
          }
        }
      ]
    }.extend(ResponseExtender)
  end

  let(:function_response) do
    {
      'id' => 'chatcmpl-456',
      'model' => 'gpt-4',
      'choices' => [
        {
          'message' => {
            'role' => 'assistant',
            'content' => nil,
            'tool_calls' => [
              {
                'id' => 'call_abc123',
                'type' => 'function',
                'function' => {
                  'name' => 'get_weather',
                  'arguments' => '{"location":"Paris"}'
                }
              }
            ]
          }
        }
      ],
      'chat_params' => { model: 'gpt-4' }
    }.extend(ResponseExtender)
  end

  describe '#content' do
    it 'returns the message content' do
      expect(basic_response.content).to eq 'Hello, how can I help you?'
    end

    it 'returns nil when content is not present' do
      expect(function_response.content).to be_nil
    end
  end

  describe '#content?' do
    it 'returns true when content is present' do
      expect(basic_response.content?).to be true
    end

    it 'returns false when content is not present' do
      expect(function_response.content?).to be false
    end
  end

  describe '#tool_calls' do
    it 'returns nil when there are no tool calls' do
      expect(basic_response.tool_calls).to be_nil
    end

    it 'returns the tool calls when present' do
      expect(function_response.tool_calls).to be_an(Array)
      expect(function_response.tool_calls.length).to eq 1
      expect(function_response.tool_calls.first['type']).to eq 'function'
    end
  end

  describe '#tool_calls?' do
    it 'returns false when there are no tool calls' do
      expect(basic_response.tool_calls?).to be false
    end

    it 'returns true when tool calls are present' do
      expect(function_response.tool_calls?).to be true
    end
  end

  describe '#functions' do
    it 'returns an empty array when there are no functions' do
      expect(basic_response.functions).to eq []
    end

    it 'returns parsed function definitions when present' do
      functions = function_response.functions
      expect(functions).to be_an(Array)
      expect(functions.length).to eq 1
      
      function = functions.first
      expect(function[:id]).to eq 'call_abc123'
      expect(function[:name]).to eq 'get_weather'
      expect(function[:arguments]).to eq({ location: 'Paris' })
    end
  end

  describe '#functions?' do
    it 'returns false when there are no functions' do
      expect(basic_response.functions?).to be false
    end

    it 'returns true when functions are present' do
      expect(function_response.functions?).to be true
    end
  end

  describe '#functions_run_all' do
    it 'raises error when no functions are present' do
      expect { basic_response.functions_run_all(context: nil) }.to raise_error(/No functions to execute/)
    end

    it 'executes functions through the provided context' do
      context = double('Context')
      expect(context).to receive(:get_weather).with(location: 'Paris').and_return({ temp: 25 })
      
      results = function_response.functions_run_all(context: context)
      expect(results).to be_an(Array)
      expect(results.length).to eq 1
      expect(results.first[:role]).to eq :tool
      expect(results.first[:tool_call_id]).to eq 'call_abc123'
      expect(results.first[:name]).to eq 'get_weather'
      expect(results.first[:content]).to include('"temp":25')
    end
  end

  describe '#chat_params' do
    it 'returns the chat parameters' do
      expect(function_response.chat_params).to eq({ model: 'gpt-4' })
    end

    it 'returns nil when chat parameters are not present' do
      expect(basic_response.chat_params).to be_nil
    end
  end

  describe '#debug_info' do
    it 'returns debug information about the response' do
      info = function_response.debug_info
      expect(info[:id]).to eq 'chatcmpl-456'
      expect(info[:model]).to eq 'gpt-4'
      expect(info[:choices_count]).to eq 1
      expect(info[:function_calls]).to be_an(Array)
      expect(info[:function_calls].first[:name]).to eq 'get_weather'
      expect(info[:function_calls].first[:args]).to include(:location)
    end
  end
end