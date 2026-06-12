require 'rails_helper'

RSpec.describe Route, type: :model do
  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:route)).to be_valid
    end
  end

  describe 'associations' do
    it 'belongs to a user' do
      expect(create(:route).user).to be_a(User)
    end

    it 'has many route_spots' do
      expect(create(:route).route_spots.first).to be_a(RouteSpot)
    end
  end

  describe 'validations' do
    it 'is invalid without a name' do
      route = build(:route, name: nil)
      expect(route).not_to be_valid
      expect(route.errors[:name]).to be_present
    end

    it 'is invalid without any route_spots' do
      route = build(:route)
      route.route_spots = []
      expect(route).not_to be_valid
      expect(route.errors[:route_spots]).to be_present
    end
  end

  describe 'route_spots ordering' do
    it 'returns route_spots ordered by position ascending' do
      route = create(:route)
      route.route_spots.destroy_all
      create(:route_spot, route: route, position: 3, spottable: create(:greentea))
      create(:route_spot, route: route, position: 1, spottable: create(:temple))
      create(:route_spot, route: route, position: 2, spottable: create(:greentea))

      expect(route.route_spots.reload.map(&:position)).to eq([1, 2, 3])
    end
  end

  describe 'accepts_nested_attributes_for :route_spots' do
    let(:user) { create(:user) }

    it 'creates nested route_spots on create' do
      route = Route.create!(
        user: user,
        name: 'ネスト作成ルート',
        route_spots_attributes: [{ spottable: create(:greentea), position: 1 }]
      )
      expect(route.route_spots.count).to eq(1)
    end

    it 'destroys nested route_spots with _destroy' do
      route = create(:route)
      first_spot = route.route_spots.first
      create(:route_spot, route: route, position: 2, spottable: create(:temple))

      route.update!(route_spots_attributes: [{ id: first_spot.id, _destroy: '1' }])

      expect(route.route_spots.reload).not_to include(first_spot)
    end
  end

  describe 'dependent: :destroy' do
    it 'destroys associated route_spots when the route is destroyed' do
      route = create(:route)
      create(:route_spot, route: route, position: 2, spottable: create(:temple))

      expect { route.destroy }.to change(RouteSpot, :count).by(-2)
    end
  end

  describe 'ransackable allowlist' do
    it 'allowlists only name and description for attributes' do
      expect(described_class.ransackable_attributes).to match_array(%w[name description])
    end

    it 'allowlists only route_spots for associations' do
      expect(described_class.ransackable_associations).to match_array(%w[route_spots])
    end
  end
end
