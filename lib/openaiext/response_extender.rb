module ResponseExtender
  def chat_params = self[:chat_params]
  def message = dig('choices', 0, 'message')
  def content = message&.dig('content')
  def content? = !content.nil?
  def tool_calls = message&.dig('tool_calls')
  def tool_calls? = !tool_calls.nil?

  def functions
    return if tool_calls.nil? || tool_calls.empty?
    
    tool_calls
      .select { |tool| tool['type'] == 'function' }
      .map { |function| build_function(function) }
  end

  def functions? = !functions.nil?

  def functions_run_all(context:)
    raise 'No functions to run' if functions.nil? || functions.empty?
    functions.map { |function| function.run(context:) }
  end

  private

  def build_function(function)
    function_info = function['function']
    {
      id: function['id'],
      name: function_info['name'],
      arguments: Oj.load(function_info['arguments'], symbol_keys: true)
    }.tap do |func|
      def func.run(context:)
        {
          tool_call_id: self[:id],
          role: :tool,
          name: self[:name],
          content: context.send(self[:name], **self[:arguments])
        }
      end
    end
  end
end
