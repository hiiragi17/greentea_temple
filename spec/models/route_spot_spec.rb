require 'rails_helper'

RSpec.describe RouteSpot, type: :model do
  describe 'associations' do
    it 'belongs to route' do
      expect(described_class.reflect_on_association(:route).macro).to eq(:belongs_to)
    end

    it 'belongs to a polymorphic spottable' do
      reflection = described_class.reflect_on_association(:spottable)

      expect(reflection.macro).to eq(:belongs_to)
      expect(reflection.options[:polymorphic]).to be(true)
    end
  end

  describe 'factory' do
    it 'is valid with the default factory' do
      expect(build(:route_spot)).to be_valid
    end

    it 'is valid with a Temple spottable' do
      expect(build(:route_spot, spottable: build(:temple))).to be_valid
    end
  end

  describe 'transport enum' do
    it 'maps the supported transports' do
      expect(described_class.transports).to eq(
        'walk' => 0, 'train' => 1, 'bus' => 2, 'car' => 3
      )
    end

    it 'allows a nil transport (optional)' do
      expect(build(:route_spot, transport: nil)).to be_valid
    end
  end

  describe 'position' do
    it 'is invalid without a position' do
      spot = build(:route_spot, position: nil)

      expect(spot).to be_invalid
      expect(spot.errors[:position]).to be_present
    end

    it 'is invalid when not an integer' do
      expect(build(:route_spot, position: 1.5)).to be_invalid
    end

    it 'is invalid when zero or negative' do
      expect(build(:route_spot, position: 0)).to be_invalid
      expect(build(:route_spot, position: -1)).to be_invalid
    end

    it 'is valid with a positive integer' do
      expect(build(:route_spot, position: 1)).to be_valid
    end
  end

  describe 'spottable_type inclusion' do
    it 'is invalid when spottable_type is not Greentea or Temple' do
      spot = build(:route_spot, spottable: nil)
      spot.spottable_type = 'Invalid'

      expect(spot).to be_invalid
      expect(spot.errors[:spottable_type]).to be_present
    end
  end

  describe '.spottable_type_for' do
    it 'converts the API spot type to the ActiveRecord class name' do
      expect(described_class.spottable_type_for('greentea')).to eq('Greentea')
      expect(described_class.spottable_type_for('temple')).to eq('Temple')
    end

    it 'returns nil for an unknown spot type' do
      expect(described_class.spottable_type_for('unknown')).to be_nil
    end
  end

  describe '#spot_type' do
    it 'converts the class name back to the API spot type' do
      expect(build(:route_spot, spottable: build(:greentea)).spot_type).to eq('greentea')
      expect(build(:route_spot, spottable: build(:temple)).spot_type).to eq('temple')
    end
  end
end
