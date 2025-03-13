module ResponseExtender
  def chat_params
    self[:chat_params]
  end

  def message
    dig('choices', 0, 'message') || {}
  end

  def content
    dig('choices', 0, 'message', 'content')
  end

  def content?
    !content.nil?
  end

  def tool_calls
    dig('choices', 0, 'message', 'tool_calls')
  end

  def tool_calls?
    !tool_calls.nil?
  end

  def functions
    return [] unless tool_calls&.any?

    tool_functions = tool_calls.select { |tool| tool['type'] == 'function' }
    return [] if tool_functions.empty?

    tool_functions.map do |function|
      function_info = function['function']
      
      begin
        arguments = Oj.load(function_info['arguments'], symbol_keys: true)
      rescue Oj::ParseError => e
        raise "Invalid function arguments JSON: #{e.message}\nArguments: #{function_info['arguments']}"
      end
      
      function_def = {
        id:        function['id'],
        name:      function_info['name'],
        arguments: arguments
      }

      function_def.define_singleton_method(:run) do |context:|
        begin
          result = context.send(self[:name], **self[:arguments])
          {
            tool_call_id: self[:id],
            role:         :tool,
            name:         self[:name],
            content:      Oj.dump(result)
          }
        rescue NoMethodError => e
          raise "Function '#{self[:name]}' not found in context: #{e.message}"
        rescue ArgumentError => e
          raise "Invalid arguments for function '#{self[:name]}': #{e.message}"
        rescue StandardError => e
          raise "Error executing function '#{self[:name]}': #{e.message}"
        end
      end

      function_def
    end
  end

  def functions_run_all(context:)
    raise 'No functions to execute' if functions.empty?

    functions.map { |function| function.run(context: context) }
  end

  def functions?
    functions.any?
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
end