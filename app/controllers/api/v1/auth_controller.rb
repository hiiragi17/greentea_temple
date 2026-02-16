module Api
  module V1
    class AuthController < BaseController
      # POST /api/v1/auth/:provider
      # Next.js側からOAuth認証コードを受け取り、JWTを発行する
      def create
        provider = params[:provider]
        code = params[:code]

        unless code.present?
          render json: { error: '認証コードが必要です' }, status: :bad_request
          return
        end

        # OAuthプロバイダーからユーザー情報を取得し、ユーザーを検索または作成
        user = find_or_create_user_from_oauth(provider, code)

        if user
          token = generate_jwt(user)
          render json: {
            data: {
              token: token,
              user: {
                id: user.id,
                name: user.name,
                role: user.role
              }
            }
          }
        else
          render json: { error: '認証に失敗しました' }, status: :unauthorized
        end
      end

      # DELETE /api/v1/auth/logout
      def destroy
        # JWTはステートレスなので、サーバー側での無効化は不要
        # クライアント側でトークンを削除する
        render json: { message: 'ログアウトしました' }
      end

      private

      def find_or_create_user_from_oauth(provider, code)
        # OAuthプロバイダーのUID取得はNextAuth.js側で行い、
        # ここではUID + providerでユーザーを検索/作成する
        uid = params[:uid]
        name = params[:name] || 'ユーザー'

        return nil unless uid.present?

        auth = Authentication.find_by(provider: provider, uid: uid)
        if auth
          auth.user
        else
          user = User.create!(name: name)
          Authentication.create!(user: user, provider: provider, uid: uid)
          user
        end
      end

      def generate_jwt(user)
        payload = {
          user_id: user.id,
          exp: 24.hours.from_now.to_i
        }
        JWT.encode(payload, jwt_secret, 'HS256')
      end
    end
  end
end
