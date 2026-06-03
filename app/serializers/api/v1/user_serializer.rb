module Api
  module V1
    class UserSerializer
      include JSONAPI::Serializer

      attributes :name, :role
    end
  end
end
