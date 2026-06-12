require 'rails_helper'

RSpec.describe TempleLike, type: :model do
  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:temple_like)).to be_valid
    end
  end

  describe 'associations' do
    it 'belongs to a user and a temple' do
      like = create(:temple_like)
      expect(like.user).to be_a(User)
      expect(like.temple).to be_a(Temple)
    end
  end

  describe 'uniqueness of (user_id, temple_id)' do
    let(:user) { create(:user) }
    let(:temple) { create(:temple) }

    before { create(:temple_like, user: user, temple: temple) }

    it 'is invalid when the same user likes the same temple twice' do
      duplicate = build(:temple_like, user: user, temple: temple)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to be_present
    end

    it 'is valid when a different user likes the same temple' do
      expect(build(:temple_like, user: create(:user), temple: temple)).to be_valid
    end

    it 'is valid when the same user likes a different temple' do
      expect(build(:temple_like, user: user, temple: create(:temple))).to be_valid
    end
  end
end
