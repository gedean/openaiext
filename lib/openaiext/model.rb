module OpenAIExt
  module Model
    GPT_BASIC_MODEL = ENV.fetch('OPENAI_GPT_BASIC_MODEL', 'gpt-4o-mini')
    GPT_ADVANCED_MODEL = ENV.fetch('OPENAI_GPT_ADVANCED_MODEL', 'gpt-4o-2024-08-06')

    O1_BASIC_MODEL = ENV.fetch('OPENAI_O1_BASIC_MODEL', 'o1-mini')
    O1_ADVANCED_MODEL = ENV.fetch('OPENAI_O1_ADVANCED_MODEL', 'o1-preview')

    def self.select(model)
      case model
      when :gpt_basic
        GPT_BASIC_MODEL
      when :gpt_advanced
        GPT_ADVANCED_MODEL
      when :o1_basic
        O1_BASIC_MODEL
      when :o1_advanced
        O1_ADVANCED_MODEL
      else
        model
      end
    end
  end
end
