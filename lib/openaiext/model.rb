module OpenAIExt
  module Model
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
    
    def self.select(model)
      MODEL_MAP.fetch(model, model)
    end
    
    def self.reasoning?(model)
      model_name = model.to_s
      model_name.start_with?('o1') || select(model).to_s.start_with?('o1')
    end
  end
end