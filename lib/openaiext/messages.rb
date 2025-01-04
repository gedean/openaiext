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
          raise ArgumentError, "Invalid message format: #{msg}"
        end
      end
    end

    def parse_hash_message(msg)
      # Verifica se a mensagem tem a estrutura básica necessária
      unless msg.key?("role") || msg.key?(:role)
        raise ArgumentError, "Invalid message format: #{msg}. Message must have 'role'"
      end

      role = (msg["role"] || msg[:role]).to_s
      content = msg["content"] || msg[:content]

      # Handle tool_calls case
      if msg.key?("tool_calls") || msg.key?(:tool_calls)
        return {
          role: role,
          tool_calls: msg["tool_calls"] || msg[:tool_calls],
          content: content
        }.compact
      end

      # Handle content formatting
      formatted_content = format_content(content)
      
      {
        role: role,
        content: formatted_content
      }.compact
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
        content.to_s
      end
    end
  end
end
