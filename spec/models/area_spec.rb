require 'rails_helper'

RSpec.describe Area, type: :model do
  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:area)).to be_valid
    end
  end

  describe 'associations' do
    it 'has many temples through temple_areas' do
      area = create(:area)
      temple = create(:temple)
      create(:temple_area, area: area, temple: temple)
      expect(area.temples).to include(temple)
    end

    it 'destroys dependent temple_areas when destroyed' do
      area = create(:area)
      create(:temple_area, area: area, temple: create(:temple))
      expect { area.destroy }.to change(TempleArea, :count).by(-1)
    end
  end

  describe 'validations' do
    it 'is invalid without a name' do
      area = build(:area, name: nil)
      expect(area).not_to be_valid
      expect(area.errors[:name]).to be_present
    end
  end

  describe 'ransackable allowlist' do
    it 'allowlists id and name for attributes' do
      expect(described_class.ransackable_attributes).to match_array(%w[id name])
    end

    it 'allowlists no associations' do
      expect(described_class.ransackable_associations).to eq([])
    end
  end
end
