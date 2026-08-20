# frozen_string_literal: true

# config/banned_words.yml の禁止ワードリストを元に、文字列に禁止ワードが含まれるか判定する。
module BannedWordFilter
  CONFIG_PATH = Rails.root.join('config/banned_words.yml')

  class << self
    def words
      @words ||= YAML.load_file(CONFIG_PATH).freeze
    end

    def match?(text)
      normalized = text.to_s.downcase
      words.any? { |word| normalized.include?(word.downcase) }
    end
  end
end
