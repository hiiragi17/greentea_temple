require 'rails_helper'

RSpec.describe Authentication, type: :model do
  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:authentication)).to be_valid
    end
  end

  describe 'associations' do
    it 'belongs to a user' do
      expect(create(:authentication).user).to be_a(User)
    end

    it 'is invalid without a user' do
      auth = build(:authentication, user: nil)
      expect(auth).not_to be_valid
      expect(auth.errors[:user]).to be_present
    end
  end
end
