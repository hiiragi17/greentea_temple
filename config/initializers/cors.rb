default_frontend_url =
  Rails.env.production? ? 'https://matcha-to-jinja.com' : 'http://localhost:3000'

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV.fetch('FRONTEND_URL', default_frontend_url)

    resource '/api/*',
             headers: :any,
             methods: %i[get post put patch delete options],
             credentials: true,
             expose: ['Authorization']
  end
end
