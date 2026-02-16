Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV.fetch('FRONTEND_URL', 'http://localhost:3000')

    resource '/api/*',
             headers: :any,
             methods: %i[get post put patch delete options head],
             credentials: true,
             expose: %w[Authorization],
             max_age: 600
  end
end
