module ResponseExtender
  def chat_params
    self[:chat_params]
  end

  def message
    dig('choices', 0, 'message')
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
      function_def = {
        id:        function['id'],
        name:      function_info['name'],
        arguments: Oj.load(function_info['arguments'], symbol_keys: true)
      }

      function_def.define_singleton_method(:run) do |context:|
        {
          tool_call_id: self[:id],
          role:         :tool,
          name:         self[:name],
          content:      Oj.dump(context.send(self[:name], **self[:arguments]))
        }
      end

      function_def
    end
  end

  def functions_run_all(context:)
    raise 'Nenhuma função para executar' if functions.empty?

    functions.map { |function| function.run(context: context) }
  end

  def functions?
    functions.any?
  end
end
