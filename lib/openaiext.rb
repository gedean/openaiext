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

  def self.single_prompt(prompt:, model: :gpt_basic, response_format: nil, max_tokens: MAX_TOKENS, store: true, metadata: nil, tools: nil, auto_run_functions: false, function_context: nil)
    chat(messages: [{ user: prompt }], model:, response_format:, max_tokens:, store:, tools:, auto_run_functions:, function_context:)
  end

  def self.single_chat(system:, user:, model: :gpt_basic, response_format: nil, max_tokens: MAX_TOKENS, store: true, metadata: nil, tools: nil, auto_run_functions: false, function_context: nil)
    chat(messages: [{ system: }, { user: }], model:, response_format:, max_tokens:, store:, tools:, auto_run_functions:, function_context:)
  end

  def self.chat(messages:, model: :gpt_basic, response_format: nil, max_tokens: MAX_TOKENS, store: true, metadata: nil, tools: nil, auto_run_functions: false, function_context: nil)
    model = OpenAIExt::Model.select(model)
    is_o1_model = model.start_with?('o1')

    messages = OpenAIExt::Messages.new(messages) unless messages.is_a?(OpenAIExt::Messages)
    
    parameters = { model:, messages:, store: }
    parameters[:metadata] = metadata if metadata

    # o1 family models doesn't support max_tokens params. Instead, use max_completion_tokens
    parameters[:max_completion_tokens] = max_tokens if is_o1_model
    parameters[:max_tokens] = max_tokens unless is_o1_model

    parameters[:response_format] = { type: 'json_object' } if response_format.eql?(:json)
    parameters[:tools] = tools if tools

    begin
      response = OpenAI::Client.new.chat(parameters:)
    rescue => e
      raise "Error in OpenAI chat: #{e.message}\nParameters: #{parameters.inspect}"
    end
    
    response[:chat_params] = parameters   
    response.extend(ResponseExtender)

    if response.functions? && auto_run_functions
      raise 'Function context not provided for auto-running functions' if function_context.nil?
      parameters[:messages] << response.message
      parameters[:messages] += response.functions_run_all(context: function_context)

      response = chat(**parameters.except(:chat_params))
    end
   
    response
  end

  def self.models = OpenAI::Client.new.models.list
end
