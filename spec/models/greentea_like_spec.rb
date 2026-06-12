require 'rails_helper'

RSpec.describe GreenteaLike, type: :model do
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
      expect(build(:greentea_like)).to be_valid
    end
  end

  describe 'uniqueness of (user_id, greentea_id)' do
    it 'is invalid when the same user likes the same greentea twice' do
      existing = create(:greentea_like)
      duplicate = build(:greentea_like, user: existing.user, greentea: existing.greentea)

      expect(duplicate).to be_invalid
      expect(duplicate.errors[:user_id]).to be_present
    end

    it 'allows a different user to like the same greentea' do
      existing = create(:greentea_like)

      expect(build(:greentea_like, greentea: existing.greentea)).to be_valid
    end

    it 'allows the same user to like a different greentea' do
      existing = create(:greentea_like)

      expect(build(:greentea_like, user: existing.user)).to be_valid
    end
  end
end
