module OpenAIExt
  class Messages < Array
<<<<<<< HEAD
    VALID_ROLES = %w[system assistant user function tool developer].freeze
=======
    VALID_ROLES = %w[system user assistant tool].freeze
>>>>>>> main

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

<<<<<<< HEAD
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
=======
      messages = [messages] unless messages.is_a?(Array)

      # Verificação se a estrutura já está no formato esperado
      return messages if messages.first.is_a?(Hash) && 
                         messages.first.key?(:role) && 
                         messages.first.key?(:content)

      messages.flat_map { |msg| parse_message(msg) }
    end

    def parse_message(msg)
      return parse_hash_message(msg) if msg.is_a?(Hash)
      raise ArgumentError, "Formato de mensagem inválido: #{msg.inspect}"
    end

    def parse_hash_message(msg)
      if msg.size == 1
        role, content = msg.first
        validate_and_format_message(role, content)
      elsif msg.key?(:role) && msg.key?(:content)
        validate_and_format_message(msg[:role], msg[:content])
      else
        msg.map { |role, content| validate_and_format_message(role, content) }
      end
    end

    def validate_and_format_message(role, content)
      role_str = role.to_s
      unless VALID_ROLES.include?(role_str)
        raise ArgumentError, "Role inválido: #{role_str}. Roles válidos: #{VALID_ROLES.join(', ')}"
>>>>>>> main
      end

      unless content.is_a?(String) || content.is_a?(Array) || content.is_a?(Hash)
        raise ArgumentError, "Conteúdo inválido: #{content.inspect}"
      end

      { role: role_str, content: content }
    end
  end
end
