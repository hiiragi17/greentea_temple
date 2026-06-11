module Api
  module V1
    class RouteSerializer
      include JSONAPI::Serializer

      attributes :name, :description

      attribute :spot_count do |obj, params|
        params[:spot_counts]&.fetch(obj.id, 0) || obj.route_spots.size
      end

      attribute :created_at, &:created_at
      attribute :updated_at, &:updated_at
    end
  end
end
