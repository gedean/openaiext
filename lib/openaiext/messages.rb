class OpenAIExt::Messages < Array

  def initialize messages = nil
    super parse_messages(messages)
  end

  def add(message) = concat(parse_messages(message))

=begin
The output format should be an array of hashes with the keys `role` and `content`.

The input can be:
  - A simple hash `{ user: 'user message' }`, which should be transformed into `{ role: 'user', content: 'user message' }`
  - A hash with multiple keys `{system: 'message', user: 'user message' }`, which should be transformed into `[{ role: 'system', content: 'message' }, { role: 'user', content: 'user message' }]`
  - An array of hashes `[{ system: 'message' }, { user: 'user message' }]`, which should be transformed into `[{ role: 'system', content: 'message' }, { role: 'user', content: 'user message' }]`

Important note: the content can be either a string or an array.
=end
  private
  def parse_messages(messages)
    return [] if messages.nil?

    messages = [messages] unless messages.is_a?(Array)
    
    # if first element is ok, then do not parse the rest
    return messages if messages.first in { role: String | Symbol, content: String | Array | Hash}

    messages.flat_map do |msg|
      if msg.is_a?(Hash)
        if msg.keys.size == 1
          role, content = msg.first
          { role: role.to_s, content: content }
        elsif msg.key?(:role) && msg.key?(:content)
          { role: msg[:role].to_s, content: msg[:content] }
        else
          msg.map { |role, content| { role: role.to_s, content: content } }
        end
      else
        raise ArgumentError, "Invalid message format: #{msg}"
      end
    end
  end
end