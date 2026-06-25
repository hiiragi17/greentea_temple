module Api
  module V1
    class AuthController < BaseController
      def create
        provider = params[:provider]
        unless OauthUserInfoFetcher::SUPPORTED_PROVIDERS.include?(provider)
          return render json: { error: 'Unsupported provider' }, status: :bad_request
        end

        user_info = OauthUserInfoFetcher.fetch(provider, auth_params.to_h.symbolize_keys)
        user = upsert_user_from(user_info)
        token = JwtService.encode(user_id: user.id, provider: provider)

        render json: {
          token: token,
          user: serialize_user_payload(user)
        }
      rescue OauthUserInfoFetcher::FetchError => e
        Rails.logger.info("OAuth token verification failed: #{e.message}")
        render json: { error: 'Unauthorized' }, status: :unauthorized
      end

      def destroy
        head :no_content
      end

      private

      def auth_params
        params.permit(:access_token, :access_token_secret)
      end

      def upsert_user_from(user_info)
        existing = Authentication.find_by(provider: user_info[:provider], uid: user_info[:uid])
        return existing.user if existing

        ActiveRecord::Base.transaction do
          user = User.create!(name: user_info[:name].presence || 'ユーザー')
          Authentication.create!(user: user, provider: user_info[:provider], uid: user_info[:uid])
          user
        end
      rescue ActiveRecord::RecordNotUnique
        Authentication.find_by!(provider: user_info[:provider], uid: user_info[:uid]).user
      end
    end
  end
end
