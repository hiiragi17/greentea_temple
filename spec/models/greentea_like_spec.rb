require 'rails_helper'

RSpec.describe GreenteaLike, type: :model do
  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:greentea_like)).to be_valid
    end
  end

  describe 'associations' do
    it 'belongs to a user and a greentea' do
      like = create(:greentea_like)
      expect(like.user).to be_a(User)
      expect(like.greentea).to be_a(Greentea)
    end
  end

  describe 'uniqueness of (user_id, greentea_id)' do
    let(:user) { create(:user) }
    let(:greentea) { create(:greentea) }

    before { create(:greentea_like, user: user, greentea: greentea) }

    it 'is invalid when the same user likes the same greentea twice' do
      duplicate = build(:greentea_like, user: user, greentea: greentea)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to be_present
    end

    it 'is valid when a different user likes the same greentea' do
      expect(build(:greentea_like, user: create(:user), greentea: greentea)).to be_valid
    end

    it 'is valid when the same user likes a different greentea' do
      expect(build(:greentea_like, user: user, greentea: create(:greentea))).to be_valid
    end
  end
end
