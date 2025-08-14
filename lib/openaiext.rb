require 'oj'
require 'openai'
require 'faraday'
require 'uri'
module OpenAIExt; end
require 'openaiext/model'
require 'openaiext/messages'
require 'openaiext/response_extender'

module OpenAIExt
  MAX_TOKENS = ENV.fetch('OPENAI_MAX_TOKENS', 16_383).to_i

  class Error < StandardError; end
  class ConfigurationError < Error; end
  class APIError < Error; end
  class FunctionExecutionError < Error; end

  class << self
    def embeddings(input, model: 'text-embedding-3-large')
      validate_input!(input, 'input')
      
      client   = client_instance
      response = client.embeddings(parameters: { input: input, model: model })
      
      def response.embeddings
        dig('data', 0, 'embedding')
      end
      
      response
    rescue Faraday::UnauthorizedError => e
      raise APIError, "Unauthorized (401). Verifique 'OPENAI_ACCESS_TOKEN' e chame 'OpenAIExt.load_config' antes de usar a API. Detalhes: #{e.message}"
    rescue OpenAI::Error => e
      raise APIError, "Embeddings API error: #{e.message}"
    end

    def vision(prompt:, image_url:, model: :gpt_advanced, response_format: nil,
               max_tokens: MAX_TOKENS, store: true, metadata: nil, tools: nil,
               auto_run_functions: false, function_context: nil)
      validate_input!(prompt, 'prompt')
      validate_url!(image_url)
      
      message_content = [
        { type: :text, text: prompt },
        { type: :image_url, image_url: { url: image_url } }
      ]
      
      chat(
        messages:           [{ role: :user, content: message_content }],
        model:              model,
        response_format:    response_format,
        max_tokens:         max_tokens,
        store:              store,
        tools:              tools,
        auto_run_functions: auto_run_functions,
        function_context:   function_context
      )
    end

    def single_prompt(prompt:, model: :gpt_basic, response_format: nil,
                      max_tokens: MAX_TOKENS, store: true, metadata: nil, tools: nil,
                      auto_run_functions: false, function_context: nil, temperature: nil,
                      top_p: nil, frequency_penalty: nil, presence_penalty: nil, prediction: nil)
      validate_input!(prompt, 'prompt')
      
      chat(
        messages:           [{ role: :user, content: prompt }],
        model:              model,
        response_format:    response_format,
        max_tokens:         max_tokens,
        store:              store,
        tools:              tools,
        auto_run_functions: auto_run_functions,
        function_context:   function_context,
        temperature:        temperature,
        top_p:              top_p,
        frequency_penalty:  frequency_penalty,
        presence_penalty:   presence_penalty,
        prediction:         prediction
      )
    end

    def single_chat(system:, user:, model: :gpt_basic, response_format: nil,
                    max_tokens: MAX_TOKENS, store: true, metadata: nil, tools: nil,
                    auto_run_functions: false, function_context: nil, temperature: nil,
                    top_p: nil, frequency_penalty: nil, presence_penalty: nil, prediction: nil)
      validate_input!(system, 'system')
      validate_input!(user, 'user')
      
      chat(
        messages:           [{ role: :system, content: system }, { role: :user, content: user }],
        model:              model,
        response_format:    response_format,
        max_tokens:         max_tokens,
        store:              store,
        tools:              tools,
        auto_run_functions: auto_run_functions,
        function_context:   function_context,
        temperature:        temperature,
        top_p:              top_p,
        frequency_penalty:  frequency_penalty,
        presence_penalty:   presence_penalty,
        prediction:         prediction
      )
    end

    def chat(messages:, model: :gpt_basic, response_format: nil, max_tokens: MAX_TOKENS,
             store: true, metadata: nil, tools: nil, auto_run_functions: false,
             function_context: nil, temperature: nil, top_p: nil, frequency_penalty: nil,
             presence_penalty: nil, prediction: nil, stream: nil, &block)
      validate_chat_parameters!(
        temperature: temperature,
        top_p: top_p,
        frequency_penalty: frequency_penalty,
        presence_penalty: presence_penalty
      )
      
      selected_model = OpenAIExt::Model.select(model)
      is_reasoning_model = OpenAIExt::Model.reasoning?(selected_model)

      messages = OpenAIExt::Messages.new(messages) unless messages.is_a?(OpenAIExt::Messages)

      parameters = build_chat_parameters(
        model: selected_model,
        messages: messages,
        max_tokens: max_tokens,
        is_reasoning_model: is_reasoning_model,
        store: store,
        metadata: metadata,
        response_format: response_format,
        tools: tools,
        temperature: temperature,
        top_p: top_p,
        frequency_penalty: frequency_penalty,
        presence_penalty: presence_penalty,
        prediction: prediction,
        stream: stream
      )

      response = execute_chat(parameters, stream, &block)
      
      return response if stream

      response[:chat_params] = parameters
      response.extend(ResponseExtender)

      if response.functions? && auto_run_functions
        handle_function_calls(response, parameters, function_context)
      else
        response
      end
    end

    def models
      @models_cache ||= client_instance.models.list
    end

    def clear_models_cache!
      @models_cache = nil
    end

    def load_config
      validate_environment!
      
      OpenAI.configure do |config|
        config.access_token      = ENV.fetch('OPENAI_ACCESS_TOKEN')
        config.organization_id   = ENV.fetch('OPENAI_ORGANIZATION_ID', nil)
        config.request_timeout   = ENV.fetch('OPENAI_REQUEST_TIMEOUT', 300).to_i
        config.log_errors        = ENV.fetch('OPENAI_LOG_ERRORS', 'true') == 'true'
      end
    end

    private

    def client_instance
      if @client.nil?
        begin
          if OpenAI.respond_to?(:configuration)
            cfg = OpenAI.configuration
            if cfg.respond_to?(:access_token) && (cfg.access_token.nil? || cfg.access_token.to_s.strip.empty?)
              load_config
            end
          else
            load_config
          end
        rescue NameError
          load_config
        end
        @client = OpenAI::Client.new
      end
      @client
    end

    def validate_environment!
      token = ENV['OPENAI_ACCESS_TOKEN']
      raise ConfigurationError, 'OPENAI_ACCESS_TOKEN environment variable is required' if token.nil? || token.strip.empty?
    end

    def validate_input!(input, name)
      raise ArgumentError, "#{name} cannot be nil or empty" if input.nil? || input.to_s.strip.empty?
    end

    def validate_url!(url)
      validate_input!(url, 'image_url')
      
      uri = URI.parse(url)
      raise ArgumentError, 'Invalid URL format' unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
    rescue URI::InvalidURIError
      raise ArgumentError, 'Invalid URL format'
    end

    def validate_chat_parameters!(temperature:, top_p:, frequency_penalty:, presence_penalty:)
      raise ArgumentError, 'temperature must be between 0 and 2' if temperature && !(0..2).cover?(temperature)
      raise ArgumentError, 'top_p must be between 0 and 1' if top_p && !(0.0..1.0).cover?(top_p)
      raise ArgumentError, 'frequency_penalty must be between -2 and 2' if frequency_penalty && !(-2..2).cover?(frequency_penalty)
      raise ArgumentError, 'presence_penalty must be between -2 and 2' if presence_penalty && !(-2..2).cover?(presence_penalty)
    end

    def build_chat_parameters(model:, messages:, max_tokens:, is_reasoning_model:, **options)
      parameters = { model: model, messages: messages, store: options[:store] }
      parameters[:metadata] = options[:metadata] if options[:metadata]
      if is_reasoning_model
        parameters[:max_completion_tokens] = max_tokens
      else
        parameters[:max_tokens] = max_tokens
      end
      parameters[:response_format] = { type: 'json_object' } if options[:response_format] == :json
      [:tools, :temperature, :top_p, :frequency_penalty, :presence_penalty, :prediction, :stream].each do |key|
        value = options[key]
        parameters[key] = value if value
      end
      parameters
    end

    def execute_chat(parameters, stream, &block)
      client = client_instance
      
      if stream
        client.chat(parameters: parameters, &block)
      else
        client.chat(parameters: parameters)
      end
    rescue Faraday::UnauthorizedError => e
      raise APIError, "Unauthorized (401). Verifique 'OPENAI_ACCESS_TOKEN' e chame 'OpenAIExt.load_config'. Detalhes: #{e.message}"
    rescue OpenAI::Error => e
      raise APIError, "Chat API error: #{e.message}"
    rescue StandardError => e
      raise APIError, "Unexpected error: #{e.message}"
    end

    def handle_function_calls(response, parameters, function_context)
      raise FunctionExecutionError, 'Function context not provided for automatic execution' if function_context.nil?

      parameters[:messages] << response.message
      parameters[:messages] += response.functions_run_all(context: function_context)

      chat(**parameters.reject { |k, _| k == :chat_params })
    end
  end
end