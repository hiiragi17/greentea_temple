require 'rails_helper'

RSpec.describe Route, type: :model do
  describe 'associations' do
    it 'belongs to user' do
      expect(described_class.reflect_on_association(:user).macro).to eq(:belongs_to)
    end

    it 'has many route_spots' do
      expect(described_class.reflect_on_association(:route_spots).macro).to eq(:has_many)
    end
  end

  describe 'factory' do
    it 'is valid with the default factory' do
      expect(build(:route)).to be_valid
    end
  end

  describe 'validations' do
    it 'is invalid without a name' do
      route = build(:route, name: nil)

      expect(route).to be_invalid
      expect(route.errors[:name]).to be_present
    end

    it 'is invalid without any route_spots' do
      route = Route.new(user: create(:user), name: 'スポット無しルート')

      expect(route).to be_invalid
      expect(route.errors[:route_spots]).to be_present
    end
  end

  describe 'route_spots ordering' do
    it 'returns route_spots ordered by position ascending' do
      route = create(:route) # comes with one spot at position 1
      route.route_spots.create!(spottable: create(:temple), position: 3)
      route.route_spots.create!(spottable: create(:greentea), position: 2)

      expect(route.route_spots.reload.pluck(:position)).to eq([1, 2, 3])
    end
  end

  describe 'nested attributes' do
    it 'creates route_spots via route_spots_attributes' do
      greentea = create(:greentea)
      route = Route.create!(
        user: create(:user),
        name: 'ネストルート',
        route_spots_attributes: [{ spottable: greentea, position: 1 }]
      )

      expect(route.route_spots.count).to eq(1)
      expect(route.route_spots.first.spottable).to eq(greentea)
    end

    it 'destroys a route_spot via _destroy' do
      route = create(:route) # spot at position 1
      extra = route.route_spots.create!(spottable: create(:temple), position: 2)

      route.update!(route_spots_attributes: [{ id: extra.id, _destroy: '1' }])

      expect(route.route_spots.reload.pluck(:id)).not_to include(extra.id)
    end
  end

  describe 'dependent destroy' do
    it 'destroys associated route_spots when the route is destroyed' do
      route = create(:route)

      expect { route.destroy }.to change(RouteSpot, :count).by(-1)
    end
  end

  describe 'ransack allowlist' do
    it 'exposes only the permitted attributes' do
      expect(described_class.ransackable_attributes).to match_array(%w[name description])
    end

    it 'exposes only the permitted associations' do
      expect(described_class.ransackable_associations).to match_array(%w[route_spots])
    end
  end
end
