# OpenAIExt

OpenAIExt is a Ruby gem that extends the functionality of the ruby-openai gem, providing additional features and a more convenient interface for working with OpenAI's APIs.

## Features

- **Simplified API** - Easy-to-use methods for common use cases
- **Enhanced Error Handling** - Detailed error messages and custom exception types
- **Streaming Support** - Built-in support for streaming responses
- **Function Calling** - Automatic function execution with context
- **Model Management** - Smart model selection with capability validation
- **Response Extensions** - Rich response objects with helper methods
- **Message Builder** - Flexible message construction with validation

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'openaiext'
```

And then execute:

```shell
bundle install
```

Or install it directly:

```shell
gem install openaiext
```

## Configuration

Set the following environment variables:

```shell
# Required
OPENAI_ACCESS_TOKEN=your_api_key

# Optional
OPENAI_ORGANIZATION_ID=your_org_id
OPENAI_REQUEST_TIMEOUT=300
OPENAI_LOG_ERRORS=true
OPENAI_MAX_TOKENS=16383

# Model Configuration
OPENAI_GPT_BASIC_MODEL=gpt-4o-mini
OPENAI_GPT_ADVANCED_MODEL=gpt-4o
OPENAI_GPT_ADVANCED_MODEL_LATEST=chatgpt-4o-latest
OPENAI_BASIC_REASONING_MODEL=o1-mini
OPENAI_ADVANCED_REASONING_MODEL=o1-preview
```

Load the configuration:

```ruby
OpenAIExt.load_config
```

## Usage

### Basic Chat

```ruby
# Single prompt
response = OpenAIExt.single_prompt(
  prompt: "What is the capital of France?",
  model: :gpt_basic
)
puts response.content

# System and user messages
response = OpenAIExt.single_chat(
  system: "You are a helpful assistant",
  user: "What is the capital of France?",
  model: :gpt_advanced
)
puts response.content

# Custom chat with multiple messages
response = OpenAIExt.chat(
  messages: [
    { system: "You are a helpful assistant" },
    { user: "What is the capital of France?" },
    { assistant: "Paris is the capital of France." },
    { user: "What is its population?" }
  ]
)
puts response.content
```

### Streaming Responses

```ruby
OpenAIExt.chat(
  messages: [{ user: "Tell me a story" }],
  stream: true
) do |chunk|
  print chunk.dig('choices', 0, 'delta', 'content')
end
```

### Vision API

```ruby
response = OpenAIExt.vision(
  prompt: "What's in this image?",
  image_url: "https://example.com/image.jpg",
  model: :gpt_advanced
)
puts response.content
```

### Embeddings

```ruby
response = OpenAIExt.embeddings("Your text here")
vector = response.embeddings
```

### Function Calling

```ruby
# Define your tools/functions
tools = [
  {
    type: "function",
    function: {
      name: "get_weather",
      description: "Get the current weather",
      parameters: {
        type: "object",
        properties: {
          location: {
            type: "string",
            description: "City name"
          }
        },
        required: ["location"]
      }
    }
  }
]

# Create a context object that implements the functions
class WeatherContext
  def get_weather(location:)
    { temperature: 20, condition: "sunny", location: location }
  end
end

# Manual function execution
response = OpenAIExt.chat(
  messages: [{ user: "What's the weather in Paris?" }],
  tools: tools
)

if response.functions?
  context = WeatherContext.new
  function_results = response.functions_run_all(context: context)
  
  # Continue the conversation with function results
  response = OpenAIExt.chat(
    messages: response.chat_params[:messages] + [response.message] + function_results
  )
end

# Automatic function execution
response = OpenAIExt.chat(
  messages: [{ user: "What's the weather in Paris?" }],
  tools: tools,
  auto_run_functions: true,
  function_context: WeatherContext.new
)
```

### Advanced Message Building

```ruby
messages = OpenAIExt::Messages.new

# Add messages using helper methods
messages.add_system("You are a helpful assistant")
messages.add_user("Hello!")
messages.add_assistant("Hi! How can I help you?")

# Add function results
messages.add_function_result(
  tool_call_id: "call_123",
  name: "get_weather",
  content: '{"temperature": 20}'
)

# Query messages
messages.by_role(:user)         # Get all user messages
messages.last_user_message      # Get the last user message
messages.last_assistant_message # Get the last assistant message
```

### Model Information

```ruby
# Get available model aliases
OpenAIExt::Model.available_models
# => [:gpt_basic, :gpt_advanced, :gpt_advanced_latest, :reasoning_basic, :reasoning_advanced]

# Get model information
info = OpenAIExt::Model.model_info(:gpt_advanced)
# => {
#   name: "gpt-4o",
#   reasoning: false,
#   vision: true,
#   json_mode: true,
#   functions: true
# }

# Check model capabilities
OpenAIExt::Model.supports_vision?(:gpt_advanced)    # => true
OpenAIExt::Model.supports_functions?(:gpt_advanced) # => true
OpenAIExt::Model.reasoning?(:reasoning_basic)       # => true
```

### Response Methods

All responses include these helper methods:

```ruby
# Content access
response.content          # Get the response content
response.content?         # Check if content exists
response.message          # Get the full message object
response.refusal          # Get refusal message if any
response.refusal?         # Check if response was refused

# Completion info
response.finish_reason    # Why the response ended
response.completed?       # Did it complete normally?
response.length_limited?  # Was it cut off due to length?
response.function_called? # Did it call a function?

# Usage statistics
response.usage            # Full usage object
response.prompt_tokens    # Number of prompt tokens
response.completion_tokens # Number of completion tokens
response.total_tokens     # Total tokens used

# Metadata
response.model            # Model used
response.created_at       # Timestamp of creation

# Function calling
response.tool_calls       # Raw tool calls
response.tool_calls?      # Check if tool calls exist
response.functions        # Parsed function objects
response.functions?       # Check if functions exist

# Utility methods
response.to_h            # Convert to hash
response.to_s            # Convert to string (returns content)
```

### Error Handling

```ruby
begin
  response = OpenAIExt.chat(messages: [{ user: "Hello" }])
rescue OpenAIExt::ConfigurationError => e
  # Handle configuration errors (missing API key, etc.)
rescue OpenAIExt::APIError => e
  # Handle API errors (rate limits, invalid requests, etc.)
rescue OpenAIExt::FunctionExecutionError => e
  # Handle function execution errors
end
```

### Advanced Parameters

All chat methods support these optional parameters:

- `model`: Model selection (see Model Information section)
- `response_format`: Set to `:json` for JSON responses
- `max_tokens`: Maximum tokens in the response
- `store`: Boolean to control response storage
- `metadata`: Additional metadata to include
- `temperature`: Controls randomness (0-2)
- `top_p`: Controls diversity via nucleus sampling (0-1)
- `frequency_penalty`: Reduces repetition (-2.0 to 2.0)
- `presence_penalty`: Encourages new topics (-2.0 to 2.0)
- `stream`: Enable streaming responses
- `tools`: Array of available tools/functions
- `auto_run_functions`: Automatically execute function calls
- `function_context`: Context object for function execution

## Development

After checking out the repo, run `bundle install` to install dependencies. Then, run `rake spec` to run the tests.

```shell
# Run tests
rake spec

# Run linter
rake rubocop

# Generate documentation
rake doc
```

## License

This gem is available under the [MIT License](LICENSE).
```