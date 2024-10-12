module OpenAIExt
  class Messages < Array
    def initialize messages = nil
      super parse_messages(messages)
    end

    def add(message) = concat(parse_messages(message))

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
end
