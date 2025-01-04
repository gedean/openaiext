require 'oj'
require 'openai'

require 'openaiext/model'
require 'openaiext/messages'
require 'openaiext/response_extender'
require 'openaiext/agent'

module OpenAIExt
  MAX_TOKENS = ENV.fetch('OPENAI_MAX_TOKENS', 16_383).to_i

  def self.embeddings(input, model: 'text-embedding-3-large')
    response = OpenAI::Client.new.embeddings(parameters: { input:, model: })
    def response.embeddings = dig('data', 0, 'embedding')
    response
  end

  def self.vision(prompt:, image_url:, model: :gpt_advanced, response_format: nil, max_tokens: MAX_TOKENS, store: true, metadata: nil, tools: nil, auto_run_functions: false, function_context: nil)
    message_content = [{ type: :text, text: prompt }, { type: :image_url, image_url: { url: image_url } }]
    chat(messages: [{ role: :user, content: message_content }], model:, response_format:, max_tokens:, store:, tools:, auto_run_functions:, function_context:)    
  end  

  def self.single_prompt(prompt:, model: :gpt_basic, response_format: nil, max_tokens: MAX_TOKENS, store: true, metadata: nil, tools: nil, auto_run_functions: false, function_context: nil, temperature: nil, top_p: nil, frequency_penalty: nil, presence_penalty: nil, prediction: nil)
    chat(messages: [{ role: 'user', content: prompt }], model:, response_format:, max_tokens:, store:, tools:, auto_run_functions:, function_context:, temperature:, top_p:, frequency_penalty:, presence_penalty:, prediction:)
  end

  def self.single_chat(system:, user:, model: :gpt_basic, response_format: nil, max_tokens: MAX_TOKENS, store: true, metadata: nil, tools: nil, auto_run_functions: false, function_context: nil, temperature: nil, top_p: nil, frequency_penalty: nil, presence_penalty: nil, prediction: nil)
    chat(
      messages: [
        { role: 'system', content: system },
        { role: 'user', content: user }
      ],
      model:,
      response_format:,
      max_tokens:,
      store:,
      tools:,
      auto_run_functions:,
      function_context:,
      temperature:,
      top_p:,
      frequency_penalty:,
      presence_penalty:,
      prediction:
    )
  end

  class << self
    def chat(messages:, model: :gpt_basic, **options)
      model = Model.select(model)
      messages = ensure_messages_format(messages)
      parameters = build_chat_parameters(messages, model, options)

      response = execute_chat(parameters)
      handle_functions(response, parameters, options)
    end

    private

    def ensure_messages_format(messages)
      messages.is_a?(Messages) ? messages : Messages.new(messages)
    end

    def build_chat_parameters(messages, model, options)
      {
        model: model,
        messages: messages,
        store: options.fetch(:store, true)
      }.tap do |params|
        add_token_params(params, model, options[:max_tokens])
        add_optional_params(params, options)
      end
    end

    def add_token_params(params, model, max_tokens)
      max_tokens ||= MAX_TOKENS
      if Model.o1?(model)
        params[:max_completion_tokens] = max_tokens
      else
        params[:max_tokens] = max_tokens
      end
    end

    def add_optional_params(params, options)
      params[:metadata] = options[:metadata] if options[:metadata]
      params[:response_format] = { type: 'json_object' } if options[:response_format] == :json
      params[:tools] = options[:tools] if options[:tools]
      
      %i[temperature top_p frequency_penalty presence_penalty prediction].each do |param|
        params[param] = options[param] if options[param]
      end
    end

    def execute_chat(parameters)
      client = OpenAI::Client.new
      
      # Garantir que o modelo está correto
      parameters[:model] = "gpt-4" # ou "gpt-3.5-turbo"
      
      # Garantir que o conteúdo da ferramenta está no formato correto
      if parameters[:messages].any? { |m| m[:role] == "tool" }
        tool_message = parameters[:messages].find { |m| m[:role] == "tool" }
        tool_message[:content] = tool_message[:content].to_json if tool_message[:content].is_a?(Array)
      end
      
      # Adicionar o tipo de conteúdo para mensagens que precisam
      parameters[:messages].each do |message|
        if message[:content].is_a?(Array)
          message[:content].each { |c| c[:type] ||= "text" }
        end
      end

      response = client.chat(parameters: parameters)
      response
    rescue => e
      raise "Error in OpenAI chat: #{e.message}"
    end

    def handle_functions(response, parameters, options)
      return response unless response.functions? && options[:auto_run_functions]
      
      raise 'Function context not provided' if options[:function_context].nil?
      
      parameters[:messages] << response.message
      parameters[:messages] += response.functions_run_all(context: options[:function_context])
      
      chat(**parameters.except(:chat_params))
    end
  end

  def self.models = OpenAI::Client.new.models.list

  def self.load_config
    OpenAI.configure do |config|
      config.access_token = ENV.fetch('OPENAI_ACCESS_TOKEN')
      config.organization_id = ENV.fetch('OPENAI_ORGANIZATION_ID')
      config.request_timeout = 300
      config.log_errors = true
    end
  end
end
