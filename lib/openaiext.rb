require 'openai'
require 'openaiext/model'
require 'openaiext/messages'
require 'openaiext/response_extender'

module OpenAIExt
  MAX_TOKENS = ENV.fetch('OPENAI_MAX_TOKENS', 16_383).to_i

  def self.embeddings(input, model: 'text-embedding-3-large')
    client   = OpenAI::Client.new
    response = client.embeddings(parameters: { input: input, model: model })
    def response.embeddings
      dig('data', 0, 'embedding')
    end
    response
  end

  def self.vision(prompt:, image_url:, model: :gpt_advanced, response_format: nil,
                  max_tokens: MAX_TOKENS, store: true, metadata: nil, tools: nil,
                  auto_run_functions: false, function_context: nil)
    message_content = [
      { type: :text, text: prompt },
      { type: :image_url, image_url: { url: image_url } }
    ]
    chat(
      messages:         [{ role: :user, content: message_content }],
      model:            model,
      response_format:  response_format,
      max_tokens:       max_tokens,
      store:            store,
      tools:            tools,
      auto_run_functions: auto_run_functions,
      function_context: function_context
    )
  end

  def self.single_prompt(prompt:, model: :gpt_basic, response_format: nil,
                         max_tokens: MAX_TOKENS, store: true, metadata: nil, tools: nil,
                         auto_run_functions: false, function_context: nil, temperature: nil,
                         top_p: nil, frequency_penalty: nil, presence_penalty: nil, prediction: nil)
    chat(
      messages:           [{ user: prompt }],
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

  def self.single_chat(system:, user:, model: :gpt_basic, response_format: nil,
                       max_tokens: MAX_TOKENS, store: true, metadata: nil, tools: nil,
                       auto_run_functions: false, function_context: nil, temperature: nil,
                       top_p: nil, frequency_penalty: nil, presence_penalty: nil, prediction: nil)
    chat(
      messages:           [{ system: system }, { user: user }],
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

  def self.chat(messages:, model: :gpt_basic, response_format: nil, max_tokens: MAX_TOKENS,
                store: true, metadata: nil, tools: nil, auto_run_functions: false,
                function_context: nil, temperature: nil, top_p: nil, frequency_penalty: nil,
                presence_penalty: nil, prediction: nil)
    selected_model = OpenAIExt::Model.select(model)
    is_reasoning_model = selected_model.start_with?('o')

    messages = OpenAIExt::Messages.new(messages) unless messages.is_a?(OpenAIExt::Messages)

    parameters = { model: selected_model, messages: messages, store: store }
    parameters[:metadata] = metadata if metadata

    if is_reasoning_model
      parameters[:max_completion_tokens] = max_tokens
    else
      parameters[:max_tokens] = max_tokens
    end

    parameters[:response_format]    = { type: 'json_object' } if response_format == :json
    parameters[:tools]              = tools if tools
    parameters[:temperature]        = temperature       if temperature
    parameters[:top_p]              = top_p             if top_p
    parameters[:frequency_penalty]  = frequency_penalty if frequency_penalty
    parameters[:presence_penalty]   = presence_penalty  if presence_penalty
    parameters[:prediction]         = prediction        if prediction

    begin
      client   = OpenAI::Client.new
      response = client.chat(parameters: parameters)
    rescue StandardError => e
      raise "Erro na comunicação com OpenAI: #{e.message}\nParâmetros: #{parameters.inspect}"
    end

    response[:chat_params] = parameters
    response.extend(ResponseExtender)

    if response.functions? && auto_run_functions
      raise 'Contexto para funções não informado para execução automática' if function_context.nil?

      parameters[:messages] << response.message
      parameters[:messages] += response.functions_run_all(context: function_context)

      response = chat(**parameters.reject { |k, _| k == :chat_params })
    end

    response
  end

  def self.models
    OpenAI::Client.new.models.list
  end

  def self.load_config
    OpenAI.configure do |config|
      config.access_token      = ENV.fetch('OPENAI_ACCESS_TOKEN')
      config.organization_id   = ENV.fetch('OPENAI_ORGANIZATION_ID')
      config.request_timeout   = 300
      config.log_errors        = true
    end
  end
end
