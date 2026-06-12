require 'rails_helper'

RSpec.describe Temple, type: :model do
  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:temple)).to be_valid
    end
  end

  describe 'validations' do
    it 'is invalid without a name' do
      temple = build(:temple, name: nil)
      expect(temple).not_to be_valid
      expect(temple.errors[:name]).to be_present
    end

    it 'is invalid without a description' do
      temple = build(:temple, description: nil)
      expect(temple).not_to be_valid
      expect(temple.errors[:description]).to be_present
    end
  end

  describe 'associations' do
    it 'has many areas through temple_areas' do
      temple = create(:temple)
      area = create(:area)
      create(:temple_area, temple: temple, area: area)
      expect(temple.areas).to include(area)
    end

    it 'has many users through temple_likes' do
      temple = create(:temple)
      user = create(:user)
      create(:temple_like, temple: temple, user: user)
      expect(temple.users).to include(user)
    end

    it 'destroys dependent likes / areas / comments when destroyed' do
      temple = create(:temple)
      create(:temple_area, temple: temple, area: create(:area))
      create(:temple_like, temple: temple, user: create(:user))
      create(:templecomment, temple: temple, user: create(:user))

      expect { temple.destroy }
        .to change(TempleArea, :count).by(-1)
        .and change(TempleLike, :count).by(-1)
        .and change(Templecomment, :count).by(-1)
    end
  end

  describe '#get_distance' do
    let(:temple) { build(:temple, latitude: 35.0, longitude: 135.0) }

    it 'returns 0 for the same coordinates' do
      expect(temple.get_distance(35.0, 135.0)).to eq(0)
    end

    it 'returns a positive distance in meters rounded to the nearest 10' do
      distance = temple.get_distance(34.99, 135.0)
      expect(distance).to be > 0
      expect((distance % 10)).to be_zero
    end
  end

  describe 'ransackable allowlist' do
    it 'allowlists name / description / address / access for attributes' do
      expect(described_class.ransackable_attributes).to match_array(%w[name description address access])
    end

    it 'allowlists areas / temple_areas for associations' do
      expect(described_class.ransackable_associations).to match_array(%w[areas temple_areas])
    end
  end
end
