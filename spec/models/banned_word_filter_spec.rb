require 'rails_helper'

RSpec.describe BannedWordFilter do
  describe '.match?' do
    it 'returns true when the text contains a banned word' do
      expect(described_class.match?('本当に死ねばいいのに')).to eq(true)
    end

    it 'is case-insensitive for ASCII banned words' do
      expect(described_class.match?('You should FUCK off')).to eq(true)
    end

    it 'returns false when the text contains no banned word' do
      expect(described_class.match?('とても美味しい抹茶パフェでした')).to eq(false)
    end

    it 'returns false for blank text' do
      expect(described_class.match?('')).to eq(false)
    end
  end
end
