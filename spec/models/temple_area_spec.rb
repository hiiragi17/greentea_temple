require 'rails_helper'

RSpec.describe TempleArea, type: :model do
  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:temple_area)).to be_valid
    end
  end

  describe 'associations' do
    it 'belongs to a temple and an area' do
      temple_area = create(:temple_area)
      expect(temple_area.temple).to be_a(Temple)
      expect(temple_area.area).to be_a(Area)
    end
  end

  describe 'ransackable allowlist' do
    it 'allowlists id / temple_id / area_id for attributes' do
      expect(described_class.ransackable_attributes).to match_array(%w[id temple_id area_id])
    end

    it 'allowlists temple / area for associations' do
      expect(described_class.ransackable_associations).to match_array(%w[temple area])
    end
  end
end
