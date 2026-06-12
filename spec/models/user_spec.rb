require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:user)).to be_valid
    end
  end

  describe 'validations' do
    it 'is invalid without a name' do
      user = build(:user, name: nil)
      expect(user).not_to be_valid
      expect(user.errors[:name]).to be_present
    end
  end

  describe 'role enum' do
    it 'defines general / admin' do
      expect(described_class.roles).to eq('general' => 0, 'admin' => 1)
    end

    it 'defaults to general' do
      expect(create(:user)).to be_general
    end
  end

  describe 'associations' do
    it 'destroys dependent records when destroyed' do
      user = create(:user)
      create(:greentea_like, user: user, greentea: create(:greentea))
      create(:temple_like, user: user, temple: create(:temple))
      create(:greenteacomment, user: user, greentea: create(:greentea))
      create(:templecomment, user: user, temple: create(:temple))
      create(:authentication, user: user)
      create(:route, user: user)

      expect { user.destroy }
        .to change(GreenteaLike, :count).by(-1)
        .and change(TempleLike, :count).by(-1)
        .and change(Greenteacomment, :count).by(-1)
        .and change(Templecomment, :count).by(-1)
        .and change(Authentication, :count).by(-1)
        .and change(Route, :count).by(-1)
    end
  end

  describe 'greentea like helpers' do
    let(:user) { create(:user) }
    let(:greentea) { create(:greentea) }

    it 'adds, checks, and removes a greentea like' do
      expect(user.greentea_like?(greentea)).to be false

      user.greentea_like(greentea)
      expect(user.greentea_like?(greentea)).to be true
      expect(user.greenteas).to include(greentea)

      user.ungreentea_like(greentea)
      expect(user.reload.greentea_like?(greentea)).to be false
    end
  end

  describe 'temple like helpers' do
    let(:user) { create(:user) }
    let(:temple) { create(:temple) }

    it 'adds, checks, and removes a temple like' do
      expect(user.temple_like?(temple)).to be false

      user.temple_like(temple)
      expect(user.temple_like?(temple)).to be true
      expect(user.temples).to include(temple)

      user.untemple_like(temple)
      expect(user.reload.temple_like?(temple)).to be false
    end
  end

  describe '#own?' do
    let(:user) { create(:user) }

    it 'returns true for an object owned by the user' do
      comment = create(:greenteacomment, user: user, greentea: create(:greentea))
      expect(user.own?(comment)).to be true
    end

    it 'returns false for an object owned by another user' do
      comment = create(:greenteacomment, user: create(:user), greentea: create(:greentea))
      expect(user.own?(comment)).to be false
    end
  end
end
