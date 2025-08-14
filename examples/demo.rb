#!/usr/bin/env ruby

require_relative '../lib/openaiext'

# Configure the gem
OpenAIExt.load_config

puts '=== OpenAIExt Demo ==='
puts

# 1. Basic chat example
puts '1. Basic Chat Example:'
response = OpenAIExt.single_prompt(
  prompt: 'What is Ruby programming language in one sentence?',
  model: :gpt_basic
)
puts "Response: #{response.content}"
puts "Tokens used: #{response.total_tokens}"
puts

# 2. System message example
puts '2. System Message Example:'
response = OpenAIExt.single_chat(
  system: 'You are a pirate. Always respond in pirate speak.',
  user: 'How are you today?',
  model: :gpt_basic
)
puts "Response: #{response.content}"
puts

# 3. Message builder example
puts '3. Message Builder Example:'
messages = OpenAIExt::Messages.new
messages.add_system('You are a helpful math tutor')
messages.add_user('What is 2+2?')
messages.add_assistant('2+2 equals 4')
messages.add_user('And what about 3+3?')

response = OpenAIExt.chat(messages: messages)
puts "Response: #{response.content}"
puts

# 4. JSON response example
puts '4. JSON Response Example:'
response = OpenAIExt.single_prompt(
  prompt: 'List 3 programming languages with their year of creation',
  model: :gpt_basic,
  response_format: :json
)
puts "Response: #{response.content}"
puts

# 5. Model information
puts '5. Model Information:'
info = OpenAIExt::Model.model_info(:gpt_advanced)
puts "Model: #{info[:name]}"
puts 'Capabilities:'
puts "  - Vision: #{info[:vision]}"
puts "  - JSON Mode: #{info[:json_mode]}"
puts "  - Functions: #{info[:functions]}"
puts "  - Reasoning: #{info[:reasoning]}"
puts

# 6. Function calling example
puts '6. Function Calling Example:'

# Define a simple calculator context
class Calculator
  def add(a:, b:)
    { result: a + b, operation: 'addition' }
  end
  
  def multiply(a:, b:)
    { result: a * b, operation: 'multiplication' }
  end
end

tools = [
  {
    type: 'function',
    function: {
      name: 'add',
      description: 'Add two numbers',
      parameters: {
        type: 'object',
        properties: {
          a: { type: 'number', description: 'First number' },
          b: { type: 'number', description: 'Second number' }
        },
        required: ['a', 'b']
      }
    }
  },
  {
    type: 'function',
    function: {
      name: 'multiply',
      description: 'Multiply two numbers',
      parameters: {
        type: 'object',
        properties: {
          a: { type: 'number', description: 'First number' },
          b: { type: 'number', description: 'Second number' }
        },
        required: ['a', 'b']
      }
    }
  }
]

response = OpenAIExt.chat(
  messages: [{ user: 'What is 15 + 27?' }],
  tools: tools,
  auto_run_functions: true,
  function_context: Calculator.new,
  model: :gpt_basic
)
puts "Response: #{response.content}"
puts

# 7. Error handling example
puts '7. Error Handling Example:'
begin
  OpenAIExt.single_prompt(prompt: "", model: :gpt_basic)
rescue ArgumentError => e
  puts "Caught error: #{e.message}"
end

puts
puts 'Demo completed!'