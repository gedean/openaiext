module OpenAIExt
  class Messages < Array
    VALID_ROLES = %w[system user assistant tool].freeze

    def initialize(messages = nil)
      super(parse_messages(messages))
    end

    def add(message)
      concat(parse_messages(message))
    end

    private

    def parse_messages(messages)
      return [] if messages.nil?

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
      end

      unless content.is_a?(String) || content.is_a?(Array) || content.is_a?(Hash)
        raise ArgumentError, "Conteúdo inválido: #{content.inspect}"
      end

      { role: role_str, content: content }
    end
  end
end
