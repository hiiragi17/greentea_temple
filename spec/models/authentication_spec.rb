require 'rails_helper'

RSpec.describe Authentication, type: :model do
  describe 'associations' do
    it 'belongs to user' do
      expect(described_class.reflect_on_association(:user).macro).to eq(:belongs_to)
    end
  end

  describe 'factory' do
    it 'is valid with the default factory' do
      expect(build(:authentication)).to be_valid
    end

    it 'persists provider and uid (Sorcery external)' do
      authentication = create(:authentication, provider: 'line', uid: 'line-001')

      expect(authentication.provider).to eq('line')
      expect(authentication.uid).to eq('line-001')
      expect(authentication.user).to be_present
    end
  end
end
