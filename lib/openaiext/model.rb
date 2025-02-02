module OpenAIExt
  module Model
    GPT_BASIC_MODEL           = ENV.fetch('OPENAI_GPT_BASIC_MODEL', 'gpt-4o-mini')
    GPT_ADVANCED_MODEL        = ENV.fetch('OPENAI_GPT_ADVANCED_MODEL', 'gpt-4o')
    GPT_ADVANCED_MODEL_LATEST = ENV.fetch('OPENAI_GPT_ADVANCED_MODEL_LATEST', 'chatgpt-4o-latest')

    O1_BASIC_MODEL            = ENV.fetch('OPENAI_O1_BASIC_MODEL', 'o1-mini')
    O1_ADVANCED_MODEL         = ENV.fetch('OPENAI_O1_ADVANCED_MODEL', 'o1-preview')

    MODEL_MAP = {
      gpt_basic:           GPT_BASIC_MODEL,
      gpt_advanced:        GPT_ADVANCED_MODEL,
      gpt_advanced_latest: GPT_ADVANCED_MODEL_LATEST,
      o1_basic:            O1_BASIC_MODEL,
      o1_advanced:         O1_ADVANCED_MODEL
    }.freeze

    def self.select(model)
      MODEL_MAP.fetch(model, model)
    end
  end
end
