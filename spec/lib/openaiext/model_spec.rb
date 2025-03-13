require 'spec_helper'
require 'openaiext/model'

RSpec.describe OpenAIExt::Model do
  describe '.select' do
    it 'returns the mapped model name for symbolic keys' do
      expect(OpenAIExt::Model.select(:gpt_basic)).to eq OpenAIExt::Model::GPT_BASIC_MODEL
      expect(OpenAIExt::Model.select(:gpt_advanced)).to eq OpenAIExt::Model::GPT_ADVANCED_MODEL
      expect(OpenAIExt::Model.select(:reasoning_basic)).to eq OpenAIExt::Model::BASIC_REASONING_MODEL
      expect(OpenAIExt::Model.select(:reasoning_advanced)).to eq OpenAIExt::Model::ADVANCED_REASONING_MODEL
    end

    it 'handles legacy o1 model names' do
      expect(OpenAIExt::Model.select(:o1_basic)).to eq OpenAIExt::Model::BASIC_REASONING_MODEL
      expect(OpenAIExt::Model.select(:o1_advanced)).to eq OpenAIExt::Model::ADVANCED_REASONING_MODEL
    end

    it 'returns the original value for unknown models' do
      expect(OpenAIExt::Model.select('gpt-4-0613')).to eq 'gpt-4-0613'
      expect(OpenAIExt::Model.select('custom-model')).to eq 'custom-model'
    end
  end

  describe '.reasoning?' do
    it 'returns true for reasoning model keys' do
      expect(OpenAIExt::Model.reasoning?(:reasoning_basic)).to be true
      expect(OpenAIExt::Model.reasoning?(:reasoning_advanced)).to be true
    end

    it 'returns true for legacy o1 model keys' do
      expect(OpenAIExt::Model.reasoning?(:o1_basic)).to be true
      expect(OpenAIExt::Model.reasoning?(:o1_advanced)).to be true
    end

    it 'returns true for model names starting with o1' do
      expect(OpenAIExt::Model.reasoning?('o1-mini')).to be true
      expect(OpenAIExt::Model.reasoning?('o1-preview')).to be true
    end

    it 'returns false for non-reasoning models' do
      expect(OpenAIExt::Model.reasoning?(:gpt_basic)).to be false
      expect(OpenAIExt::Model.reasoning?('gpt-4')).to be false
      expect(OpenAIExt::Model.reasoning?('custom-model')).to be false
    end
  end
end