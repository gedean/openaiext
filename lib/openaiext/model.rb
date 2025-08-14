module OpenAIExt::Model
    # GPT Models
    GPT_BASIC_MODEL           = ENV.fetch('OPENAI_GPT_BASIC_MODEL', 'gpt-4o-mini')
    GPT_ADVANCED_MODEL        = ENV.fetch('OPENAI_GPT_ADVANCED_MODEL', 'gpt-4o')
    GPT_ADVANCED_MODEL_LATEST = ENV.fetch('OPENAI_GPT_ADVANCED_MODEL_LATEST', 'chatgpt-4o-latest')
    
    # Reasoning Models (formerly known as O1 models)
    BASIC_REASONING_MODEL     = ENV.fetch('OPENAI_BASIC_REASONING_MODEL', 'o1-mini')
    ADVANCED_REASONING_MODEL  = ENV.fetch('OPENAI_ADVANCED_REASONING_MODEL', 'o1-preview')
    
    # Model name mapping
    MODEL_MAP = {
      # GPT models
      gpt_basic:           GPT_BASIC_MODEL,
      gpt_advanced:        GPT_ADVANCED_MODEL,
      gpt_advanced_latest: GPT_ADVANCED_MODEL_LATEST,
      
      # Reasoning models
      reasoning_basic:     BASIC_REASONING_MODEL,
      reasoning_advanced:  ADVANCED_REASONING_MODEL,
      
      # Legacy model names (for backward compatibility)
      o1_basic:            BASIC_REASONING_MODEL,
      o1_advanced:         ADVANCED_REASONING_MODEL
    }.freeze
    
    # Model capabilities
    VISION_MODELS = %w[gpt-4-vision-preview gpt-4o gpt-4o-mini].freeze
    JSON_MODE_MODELS = %w[gpt-3.5-turbo-1106 gpt-4-1106-preview gpt-4o gpt-4o-mini].freeze
    FUNCTION_CALLING_MODELS = %w[gpt-3.5-turbo gpt-4 gpt-4-turbo gpt-4o gpt-4o-mini].freeze
    
    class << self
      def select(model)
        return model.to_s if model.to_s.include?('-') || model.to_s.include?('.')
        
        MODEL_MAP.fetch(model) do
          raise ArgumentError, "Unknown model alias: #{model}. Available aliases: #{MODEL_MAP.keys.join(', ')}"
        end
      end
      
      def reasoning?(model)
        model_name = select(model).to_s
        model_name.start_with?('o1-') || model_name.start_with?('o3-')
      end
      
      def supports_vision?(model)
        model_name = select(model).to_s
        VISION_MODELS.any? { |vm| model_name.include?(vm) }
      end
      
      def supports_json_mode?(model)
        model_name = select(model).to_s
        JSON_MODE_MODELS.any? { |jm| model_name.include?(jm) }
      end
      
      def supports_functions?(model)
        model_name = select(model).to_s
        return false if reasoning?(model)
        
        FUNCTION_CALLING_MODELS.any? { |fm| model_name.include?(fm) }
      end
      
      def validate_model_capabilities!(model, capabilities)
        model_name = select(model)
        
        if capabilities[:vision] && !supports_vision?(model_name)
          raise ArgumentError, "Model #{model_name} does not support vision"
        end
        
        if capabilities[:json_mode] && !supports_json_mode?(model_name)
          raise ArgumentError, "Model #{model_name} does not support JSON mode"
        end
        
        if capabilities[:functions] && !supports_functions?(model_name)
          raise ArgumentError, "Model #{model_name} does not support function calling"
        end
      end
      
      def available_models
        MODEL_MAP.keys
      end
      
      def model_info(model)
        model_name = select(model)
        
        {
          name: model_name,
          reasoning: reasoning?(model_name),
          vision: supports_vision?(model_name),
          json_mode: supports_json_mode?(model_name),
          functions: supports_functions?(model_name)
        }
      end
    end
end