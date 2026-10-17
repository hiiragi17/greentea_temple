default_frontend_url =
  Rails.env.production? ? 'https://matcha-to-jinja.vercel.app' : 'http://localhost:3000'

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV.fetch('FRONTEND_URL', default_frontend_url)

    # 認証は Bearer ヘッダーのみで Cookie は使わないため、credentials は許可しない。
    resource '/api/*',
             headers: :any,
             methods: %i[get post put patch delete options]
  end
end
