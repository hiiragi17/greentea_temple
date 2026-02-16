Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV.fetch('FRONTEND_URL', 'http://localhost:3001')

    resource '/api/*',
             headers: :any,
             methods: %i[get post put patch delete options head],
             credentials: true
  end
end
