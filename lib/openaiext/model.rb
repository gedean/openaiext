module OpenAIExt
  module Model
    GPT_BASIC_MODEL           = ENV.fetch('OPENAI_GPT_BASIC_MODEL', 'gpt-4o-mini')
    GPT_ADVANCED_MODEL        = ENV.fetch('OPENAI_GPT_ADVANCED_MODEL', 'gpt-4o')
    GPT_ADVANCED_MODEL_LATEST = ENV.fetch('OPENAI_GPT_ADVANCED_MODEL_LATEST', 'chatgpt-4o-latest')

    BASIC_REASONING_MODEL     = ENV.fetch('OPENAI_BASIC_REASONING_MODEL', 'o1-mini')
    ADVANCED_REASONING_MODEL  = ENV.fetch('OPENAI_ADVANCED_REASONING_MODEL', 'o1-preview')

    MODEL_MAP = {
      gpt_basic:           GPT_BASIC_MODEL,
      gpt_advanced:        GPT_ADVANCED_MODEL,
      gpt_advanced_latest: GPT_ADVANCED_MODEL_LATEST,
      reasoning_basic:     BASIC_REASONING_MODEL,
      reasoning_advanced:  ADVANCED_REASONING_MODEL
    }.freeze

    def self.select(model)
      MODEL_MAP.fetch(model, model)
    end
  end
end
