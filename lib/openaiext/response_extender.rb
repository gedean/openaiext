module ResponseExtender
  def chat_params
    self['chat_params']
  end

  def message
    dig('choices', 0, 'message') || {}
  end

  def content
    dig('choices', 0, 'message', 'content')
  end

  def content?
    !content.nil? && !content.empty?
  end

  def tool_calls
    dig('choices', 0, 'message', 'tool_calls')
  end

  def tool_calls?
    !tool_calls.nil? && !tool_calls.empty?
  end

  def refusal
    dig('choices', 0, 'message', 'refusal')
  end

  def refusal?
    !refusal.nil?
  end

  def finish_reason
    dig('choices', 0, 'finish_reason')
  end

  def completed?
    finish_reason == 'stop'
  end

  def length_limited?
    finish_reason == 'length'
  end

  def function_called?
    finish_reason == 'tool_calls' || finish_reason == 'function_call'
  end

  def usage
    self['usage'] || {}
  end

  def prompt_tokens
    usage['prompt_tokens'] || 0
  end

  def completion_tokens
    usage['completion_tokens'] || 0
  end

  def total_tokens
    usage['total_tokens'] || 0
  end

  def model
    self['model']
  end

  def created_at
    Time.at(self['created']) if self['created']
  end

  def functions
    return [] unless tool_calls?

    tool_functions = tool_calls.select { |tool| tool['type'] == 'function' }
    return [] if tool_functions.empty?

    tool_functions.map { |function| build_function_object(function) }
  end

  def functions?
    functions.any?
  end

  def functions_run_all(context:)
    raise OpenAIExt::FunctionExecutionError, 'No functions to execute' if functions.empty?
    raise OpenAIExt::FunctionExecutionError, 'Context cannot be nil' if context.nil?

    functions.map { |function| function.run(context: context) }
  end

  def to_h
    {
      content: content,
      role: message['role'],
      model: model,
      finish_reason: finish_reason,
      usage: usage,
      created_at: created_at
    }.compact
  end

  def to_s
    content || '[No content]'
  end

  def inspect
    truncated_content = content ? content[0..50].gsub(/\s+/, ' ').strip : nil
    "#<OpenAIExt::Response model=#{model} finish_reason=#{finish_reason} content=#{truncated_content.inspect}>"
  end

  # Helper method for debugging response structure
  def debug_info
    {
      id: self['id'],
      model: self['model'],
      choices_count: self['choices']&.length || 0,
      function_calls: functions.map { |f| { name: f[:name], args: f[:arguments].keys } }
    }
  end

  private

  def build_function_object(function)
    function_info = function['function']
    
    begin
      arguments = parse_function_arguments(function_info['arguments'])
    rescue => e
      raise OpenAIExt::FunctionExecutionError, "Failed to parse function arguments: #{e.message}"
    end
    
    function_def = {
      id:        function['id'],
      name:      function_info['name'],
      arguments: arguments
    }

    define_function_run_method(function_def)
    function_def
  end

  def parse_function_arguments(arguments_json)
    return {} if arguments_json.nil? || arguments_json.empty?
    
    Oj.load(arguments_json, symbol_keys: true)
  rescue Oj::ParseError => e
    raise "Invalid JSON: #{e.message}\nArguments: #{arguments_json}"
  end

  def define_function_run_method(function_def)
    function_def.define_singleton_method(:run) do |context:|
      function_name = self[:name]
      function_id = self[:id]
      function_args = self[:arguments]
      
      unless context.respond_to?(function_name)
        raise OpenAIExt::FunctionExecutionError, 
              "Function '#{function_name}' not found in context. Available methods: #{context.public_methods(false).sort.join(', ')}"
      end
      
      begin
        result = if function_args.empty?
                   context.public_send(function_name)
                 else
                   context.public_send(function_name, **function_args)
                 end
        
        {
          tool_call_id: function_id,
          role:         :tool,
          name:         function_name,
          content:      case result
                        when String then result
                        when nil then 'null'
                        else Oj.dump(result, mode: :compat)
                        end
        }
      rescue ArgumentError => e
        raise OpenAIExt::FunctionExecutionError, 
              "Invalid arguments for function '#{function_name}': #{e.message}"
      rescue NoMethodError => e
        raise OpenAIExt::FunctionExecutionError, 
              "Method error in function '#{function_name}': #{e.message}"
      rescue => e
        raise OpenAIExt::FunctionExecutionError, 
              "Error executing function '#{function_name}': #{e.class} - #{e.message}"
      end
    end
  end

end