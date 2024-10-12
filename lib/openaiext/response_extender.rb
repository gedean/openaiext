require 'openai'
require 'openaiext/messages'

module OpenAIExt
  GPT_BASIC_MODEL = ENV.fetch('OPENAI_GPT_BASIC_MODEL', 'gpt-4o-mini')
  GPT_ADVANCED_MODEL = ENV.fetch('OPENAI_GPT_ADVANCED_MODEL', 'gpt-4o-2024-08-06')

  O1_BASIC_MODEL = ENV.fetch('OPENAI_O1_BASIC_MODEL', 'o1-mini')
  O1_ADVANCED_MODEL = ENV.fetch('OPENAI_O1_ADVANCED_MODEL', 'o1-preview')
  
  MAX_TOKENS = ENV.fetch('OPENAI_MAX_TOKENS', 16_383).to_i

  module ResponseExtender
    def chat_params = self[:chat_params]

    def message = dig('choices', 0, 'message')

    def content = dig('choices', 0, 'message', 'content')
    def content? = !content.nil?

    def tool_calls = dig('choices', 0, 'message', 'tool_calls')
    def tool_calls? = !tool_calls.nil?

    def functions
      return if tool_calls.nil?
      
      functions = tool_calls.filter { |tool| tool['type'].eql? 'function' }
      return if functions.empty?
      
      functions_list = []
      functions.map.with_index do |function, function_index|
        function_info = tool_calls.dig(function_index, 'function')
        function_def = { id: function['id'], name: function_info['name'], arguments: Oj.load(function_info['arguments'], symbol_keys: true) }
        
        def function_def.run(context:)
          {
            tool_call_id: self[:id],
            role: :tool,
            name: self[:name],
            content: context.send(self[:name], **self[:arguments])
          }
        end

        functions_list << function_def
      end

      functions_list
    end

    def functions_run_all(context:)
      raise 'No functions to run' if functions.nil?
      functions.map { |function| function.run(context:) }
    end

    def functions? = !functions.nil?
  end

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
    model = select_model(model)
    is_o1_model = model.start_with?('o1')

    messages = IntelliAgent::OpenAI::Messages.new(messages) unless messages.is_a?(IntelliAgent::OpenAI::Messages)
    
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

  def self.select_model(model)
    case model
    when :gpt_basic
      GPT_BASIC_MODEL
    when :gpt_advanced
      GPT_ADVANCED_MODEL
    when :o1_basic
      O1_BASIC_MODEL
    when :o1_advanced
      O1_ADVANCED_MODEL
    else
      model
    end
  end
end
