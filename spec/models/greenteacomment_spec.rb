require 'rails_helper'

RSpec.describe Greenteacomment, type: :model do
  describe 'associations' do
    it 'belongs to user' do
      expect(described_class.reflect_on_association(:user).macro).to eq(:belongs_to)
    end

    it 'belongs to greentea' do
      expect(described_class.reflect_on_association(:greentea).macro).to eq(:belongs_to)
    end
  end

  describe 'factory' do
    it 'is valid with the default factory' do
      expect(build(:greenteacomment)).to be_valid
    end
  end

  describe 'validations' do
    it 'is invalid without a body' do
      comment = build(:greenteacomment, body: nil)

      expect(comment).to be_invalid
      expect(comment.errors[:body]).to be_present
    end

    it 'is valid at the 65,535 character boundary' do
      expect(build(:greenteacomment, body: 'a' * 65_535)).to be_valid
    end

    it 'is invalid beyond 65,535 characters' do
      comment = build(:greenteacomment, body: 'a' * 65_536)

      expect(comment).to be_invalid
      expect(comment.errors[:body]).to be_present
    end
  end
end
