module OpenAIExt
  class Messages < Array
    VALID_ROLES = %w[system assistant user function tool developer].freeze

    def initialize(messages = nil)
      super(parse_messages(messages))
    end

    def add(message)
      concat(parse_messages(message))
    end

    private

    def parse_messages(messages)
      return [] if messages.nil?
      messages = Array(messages)
      
      messages.flat_map do |msg|
        case msg
        when Hash
          parse_hash_message(msg)
        else
          raise ArgumentError, "Invalid message format: #{msg.inspect}"
        end
      end
    end

    def parse_hash_message(msg)
      # Check if the message has a standard format with 'role' key
      if msg.key?(:role) || msg.key?('role')
        role = (msg[:role] || msg['role']).to_s
        content = msg[:content] || msg['content']

        # Handle tool_calls case
        if msg.key?(:tool_calls) || msg.key?('tool_calls')
          return {
            role: role,
            tool_calls: msg[:tool_calls] || msg['tool_calls'],
            content: content
          }.compact
        end

        return { role: role, content: format_content(content) }.compact
      end
      
      # Handle simplified format like { user: "message" }
      if msg.size == 1
        role, content = msg.first
        role_str = role.to_s
        
        unless VALID_ROLES.include?(role_str)
          raise ArgumentError, "Invalid role: #{role_str}. Valid roles: #{VALID_ROLES.join(', ')}"
        end
        
        return { role: role_str, content: format_content(content) }
      end
      
      # If we reach here, it's an invalid format
      raise ArgumentError, "Invalid message format: #{msg.inspect}"
    end

    def format_content(content)
      case content
      when String
        content
      when Array
        content.map do |item|
          case item
          when Hash
            item.transform_keys(&:to_s)
          else
            item
          end
        end
      when Hash
        # Convert single content object to array format
        [content.transform_keys(&:to_s)]
      when nil
        nil
      else
        raise ArgumentError, "Invalid content type: #{content.class}. Must be String, Array, Hash, or nil."
      end
    end
  end
end