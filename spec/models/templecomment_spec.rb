require 'rails_helper'

RSpec.describe Templecomment, type: :model do
  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:templecomment)).to be_valid
    end
  end

  describe 'associations' do
    it 'belongs to a user and a temple' do
      comment = create(:templecomment)
      expect(comment.user).to be_a(User)
      expect(comment.temple).to be_a(Temple)
    end
  end

  describe 'body validation' do
    it 'is invalid without a body' do
      comment = build(:templecomment, body: nil)
      expect(comment).not_to be_valid
      expect(comment.errors[:body]).to be_present
    end

    it 'is invalid with a blank body' do
      expect(build(:templecomment, body: '')).not_to be_valid
    end

    it 'is valid at the 65,535 character boundary' do
      expect(build(:templecomment, body: 'あ' * 65_535)).to be_valid
    end

    it 'is invalid above the 65,535 character limit' do
      comment = build(:templecomment, body: 'あ' * 65_536)
      expect(comment).not_to be_valid
      expect(comment.errors[:body]).to be_present
    end
  end
end
