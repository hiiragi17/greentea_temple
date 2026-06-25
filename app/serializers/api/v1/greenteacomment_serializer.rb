module Api
  module V1
    class GreenteacommentSerializer
      include JSONAPI::Serializer

      attributes :body, :created_at

      attribute :user do |obj|
        { id: obj.user_id, name: obj.user&.name }
      end

      attribute :owned_by_current_user do |obj, params|
        params[:current_user_id].present? && obj.user_id == params[:current_user_id]
      end
    end
  end
end
