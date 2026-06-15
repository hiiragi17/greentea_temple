require 'rails_helper'

RSpec.describe RouteSpot, type: :model do
  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:route_spot)).to be_valid
    end
  end

  describe 'associations' do
    it 'belongs to a route' do
      expect(create(:route_spot, position: 2).route).to be_a(Route)
    end

    it 'accepts a greentea as polymorphic spottable' do
      spot = create(:route_spot, position: 2, spottable: create(:greentea))
      expect(spot.spottable).to be_a(Greentea)
      expect(spot.spottable_type).to eq('Greentea')
    end

    it 'accepts a temple as polymorphic spottable' do
      spot = create(:route_spot, position: 2, spottable: create(:temple))
      expect(spot.spottable).to be_a(Temple)
      expect(spot.spottable_type).to eq('Temple')
    end
  end

  describe 'transport enum' do
    it 'defines walk/train/bus/car' do
      expect(described_class.transports).to eq('walk' => 0, 'train' => 1, 'bus' => 2, 'car' => 3)
    end

    it 'allows a nil transport (任意項目)' do
      expect(build(:route_spot, transport: nil)).to be_valid
    end

    it 'raises for an unknown transport value' do
      expect { build(:route_spot, transport: 'plane') }.to raise_error(ArgumentError)
    end
  end

  describe 'position validation' do
    it 'is invalid without a position' do
      spot = build(:route_spot, position: nil)
      expect(spot).not_to be_valid
      expect(spot.errors[:position]).to be_present
    end

    it 'is invalid when position is zero' do
      expect(build(:route_spot, position: 0)).not_to be_valid
    end

    it 'is invalid when position is negative' do
      expect(build(:route_spot, position: -1)).not_to be_valid
    end

    it 'is invalid when position is not an integer' do
      expect(build(:route_spot, position: 1.5)).not_to be_valid
    end
  end

  describe 'spottable_type inclusion' do
    it 'is invalid for an unsupported spottable_type' do
      spot = build(:route_spot)
      spot.spottable_type = 'User'
      expect(spot).not_to be_valid
      expect(spot.errors[:spottable_type]).to be_present
    end
  end

  describe '.spottable_type_for' do
    it 'maps "greentea" to "Greentea"' do
      expect(described_class.spottable_type_for('greentea')).to eq('Greentea')
    end

    it 'maps "temple" to "Temple"' do
      expect(described_class.spottable_type_for('temple')).to eq('Temple')
    end

    it 'returns nil for an unknown spot type' do
      expect(described_class.spottable_type_for('unknown')).to be_nil
    end
  end

  describe '.spottable_class_for' do
    it 'maps "greentea" to Greentea' do
      expect(described_class.spottable_class_for('greentea')).to eq(Greentea)
    end

    it 'maps "temple" to Temple' do
      expect(described_class.spottable_class_for('temple')).to eq(Temple)
    end

    it 'returns nil for an unknown spot type' do
      expect(described_class.spottable_class_for('unknown')).to be_nil
    end
  end

  describe '#spot_type' do
    it 'returns "greentea" for a Greentea spottable' do
      expect(build(:route_spot, spottable: build(:greentea)).spot_type).to eq('greentea')
    end

    it 'returns "temple" for a Temple spottable' do
      expect(build(:route_spot, spottable: build(:temple)).spot_type).to eq('temple')
    end
  end
end
