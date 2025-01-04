module OpenAIExt
  module Model
    MODELS = {
      gpt_basic: ENV.fetch('OPENAI_GPT_BASIC_MODEL', 'gpt-4o-mini'),
      gpt_advanced: ENV.fetch('OPENAI_GPT_ADVANCED_MODEL', 'gpt-4o'),
      gpt_advanced_latest: ENV.fetch('OPENAI_GPT_ADVANCED_MODEL_LATEST', 'chatgpt-4o-latest'),
      o1_basic: ENV.fetch('OPENAI_O1_BASIC_MODEL', 'o1-mini'),
      o1_advanced: ENV.fetch('OPENAI_O1_ADVANCED_MODEL', 'o1-preview')
    }.freeze

    def self.select(model)
      MODELS[model] || model
    end

    def self.o1?(model)
      select(model).to_s.start_with?('o1')
    end
  end
end
