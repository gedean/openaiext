module OpenAIExt
  class Messages < Array
    VALID_ROLES = %w[system assistant user function tool developer].freeze

    class InvalidMessageError < StandardError; end
    class InvalidRoleError < ArgumentError; end
    class InvalidContentError < StandardError; end

    def initialize(messages = nil)
      super(parse_messages(messages))
    end

    def add(message)
      concat(parse_messages(message))
    end

    def add_system(content)
      add({ role: :system, content: content })
    end

    def add_user(content)
      add({ role: :user, content: content })
    end

    def add_assistant(content)
      add({ role: :assistant, content: content })
    end

    def add_function_result(tool_call_id:, name:, content:)
      add({
        tool_call_id: tool_call_id,
        role: :tool,
        name: name,
        content: content
      })
    end

    def by_role(role)
      select { |msg| msg[:role] == role.to_s }
    end

    def last_user_message
      reverse.find { |msg| msg[:role] == 'user' }
    end

    def last_assistant_message
      reverse.find { |msg| msg[:role] == 'assistant' }
    end

    def to_s
      map { |msg| "#{msg[:role]}: #{msg[:content]}" }.join("\n")
    end

    private

    def parse_messages(messages)
      return [] if messages.nil?
      
      # If it's a single message hash with role key, wrap it in an array
      if messages.is_a?(Hash) && (messages.key?(:role) || messages.key?('role'))
        messages = [messages]
      else
        messages = Array(messages)
      end
      
      messages.flat_map { |msg| parse_single_message(msg) }
    end

    def parse_single_message(msg)
      case msg
      when Hash
        parse_hash_message(msg)
      when Array
        parse_array_message(msg)
      else
        raise InvalidMessageError, "Invalid message format: #{msg.inspect}. Expected Hash or Array"
      end
    end

    def parse_array_message(msg)
      unless msg.size == 2 && msg[0].is_a?(Symbol)
        raise InvalidMessageError, "Invalid array message format: #{msg.inspect}. Expected [role, content]"
      end
      
      role = msg[0].to_s
      validate_role!(role)
      
      { role: role, content: format_content(msg[1]) }
    end

    def parse_hash_message(msg)
      if msg.key?(:role) || msg.key?('role')
        parse_standard_message(msg)
      elsif msg.size == 1
        parse_shorthand_message(msg)
      else
        raise InvalidMessageError, "Invalid message format: #{msg.inspect}"
      end
    end

    def parse_standard_message(msg)
      role = (msg[:role] || msg['role']).to_s
      validate_role!(role)
      
      content = msg[:content] || msg['content']
      
      message = { role: role }
      
      if msg.key?(:tool_calls) || msg.key?('tool_calls')
        message[:tool_calls] = msg[:tool_calls] || msg['tool_calls']
      end
      
      if msg.key?(:tool_call_id) || msg.key?('tool_call_id')
        message[:tool_call_id] = msg[:tool_call_id] || msg['tool_call_id']
      end
      
      if msg.key?(:name) || msg.key?('name')
        message[:name] = msg[:name] || msg['name']
      end
      
      message[:content] = format_content(content) unless content.nil?
      
      message
    end

    def parse_shorthand_message(msg)
      role, content = msg.first
      role_str = role.to_s
      
      validate_role!(role_str)
      
      { role: role_str, content: format_content(content) }
    end

    def validate_role!(role)
      unless VALID_ROLES.include?(role)
        raise InvalidRoleError, "Invalid role: '#{role}'. Valid roles: #{VALID_ROLES.join(', ')}"
      end
    end

    def format_content(content)
      case content
      when String
        content
      when Array
        validate_content_array!(content)
        content.map { |item| format_content_item(item) }
      when Hash
        [format_content_item(content)]
      when nil
        nil
      else
        raise InvalidContentError, "Invalid content type: #{content.class}. Must be String, Array, Hash, or nil"
      end
    end

    def validate_content_array!(content)
      if content.empty?
        raise InvalidContentError, "Content array cannot be empty"
      end
      
      unless content.all? { |item| item.is_a?(Hash) || item.is_a?(String) }
        raise InvalidContentError, "Content array items must be Hash or String"
      end
    end

    def format_content_item(item)
      case item
      when Hash
        validate_content_hash!(item)
        item.transform_keys(&:to_s)
      when String
        { 'type' => 'text', 'text' => item }
      else
        item
      end
    end

    def validate_content_hash!(hash)
      unless hash.key?(:type) || hash.key?('type')
        raise InvalidContentError, "Content hash must have a 'type' key"
      end
    end
  end
end