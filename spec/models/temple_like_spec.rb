require 'rails_helper'

RSpec.describe TempleLike, type: :model do
  describe 'associations' do
    it 'belongs to user' do
      expect(described_class.reflect_on_association(:user).macro).to eq(:belongs_to)
    end

    it 'belongs to temple' do
      expect(described_class.reflect_on_association(:temple).macro).to eq(:belongs_to)
    end
  end

  describe 'factory' do
    it 'is valid with the default factory' do
      expect(build(:temple_like)).to be_valid
    end
  end

  describe 'uniqueness of (user_id, temple_id)' do
    it 'is invalid when the same user likes the same temple twice' do
      existing = create(:temple_like)
      duplicate = build(:temple_like, user: existing.user, temple: existing.temple)

      expect(duplicate).to be_invalid
      expect(duplicate.errors[:user_id]).to be_present
    end

    it 'allows a different user to like the same temple' do
      existing = create(:temple_like)

      expect(build(:temple_like, temple: existing.temple)).to be_valid
    end

    it 'allows the same user to like a different temple' do
      existing = create(:temple_like)

      expect(build(:temple_like, user: existing.user)).to be_valid
    end
  end
end
