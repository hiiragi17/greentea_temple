# frozen_string_literal: true

# 荒らし対策: body に禁止ワード（config/banned_words.yml）が含まれる場合はバリデーションエラーにする。
module BannedWordValidatable
  extend ActiveSupport::Concern

  included do
    validate :body_must_not_contain_banned_word
  end

  private

  def body_must_not_contain_banned_word
    return if body.blank?
    return unless BannedWordFilter.match?(body)

    errors.add(:body, 'に不適切な言葉が含まれています')
  end
end
