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
