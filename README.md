# OpenAIExt

OpenAIExt is a Ruby gem that extends the functionality of the ruby-openai gem, providing additional features and a more convenient interface for working with OpenAI's APIs.

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
OPENAI_ACCESS_TOKEN=your_api_key
OPENAI_ORGANIZATION_ID=your_org_id
```

Optional environment variables for model configuration:

```shell
OPENAI_MAX_TOKENS=16383
OPENAI_GPT_BASIC_MODEL=gpt-4-turbo
OPENAI_GPT_ADVANCED_MODEL=gpt-4
OPENAI_GPT_ADVANCED_MODEL_LATEST=gpt-4-latest
OPENAI_BASIC_REASONING_MODEL=claude-3-sonnet
OPENAI_ADVANCED_REASONING_MODEL=claude-3-opus
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

### Vision API

```ruby
response = OpenAIExt.vision(
  prompt: "What's in this image?",
  image_url: "https://example.com/image.jpg"
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
class Context
  def get_weather(location:)
    # Implement weather lookup
    { temperature: 20, condition: "sunny" }
  end
end

# Make the API call with automatic function execution
response = OpenAIExt.chat(
  messages: [{ user: "What's the weather in Paris?" }],
  tools: tools,
  auto_run_functions: true,
  function_context: Context.new
)
```

### Advanced Parameters

All chat methods support these optional parameters:

- `model`: `:gpt_basic`, `:gpt_advanced`, `:gpt_advanced_latest`, `:reasoning_basic`, `:reasoning_advanced`, or any valid OpenAI model ID
- `response_format`: Set to `:json` for JSON responses
- `max_tokens`: Maximum tokens in the response
- `store`: Boolean to control response storage
- `metadata`: Additional metadata to include
- `temperature`: Controls randomness (0-2)
- `top_p`: Controls diversity via nucleus sampling
- `frequency_penalty`: Reduces repetition (-2.0 to 2.0)
- `presence_penalty`: Encourages new topics (-2.0 to 2.0)

## Response Methods

All responses include these helper methods:

- `content`: Get the response content
- `content?`: Check if content exists
- `message`: Get the full message object
- `tool_calls`: Get tool calls if any
- `tool_calls?`: Check if tool calls exist
- `functions`: Get parsed function calls
- `functions?`: Check if functions exist
- `chat_params`: Get the original chat parameters

## License

This gem is available under the [MIT License](LICENSE).
```
