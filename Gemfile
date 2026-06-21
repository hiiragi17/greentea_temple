source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.3.11"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 7.1.0"

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "sprockets-rails"

# Use postgresql as the database for Active Record
gem "pg", "~> 1.6"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", "~> 8.0"

# Rack 3 は capybara 3.40 + puma 5 と非互換（rack/handler 削除）。
# Rack 3 化は puma 6 / capybara 更新と合わせて別途対応する。
gem "rack", "~> 2.2"

# Bundle and transpile JavaScript [https://github.com/rails/jsbundling-rails]
gem "jsbundling-rails"

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"

# Bundle and process CSS [https://github.com/rails/cssbundling-rails]
gem "cssbundling-rails"

# Use Redis adapter to run Action Cable in production
# gem "redis", "~> 4.0"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ mingw mswin x64_mingw jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Model
gem 'enum_help'

# Authentication
gem 'sorcery', '~> 0.18'
gem 'oauth2'
gem 'config'

# CORS for API (#113)
gem 'rack-cors'

# JSON serializer for API (#114)
gem 'jsonapi-serializer', '~> 2.2'

# JWT for API authentication (#115)
gem 'jwt', '~> 3.2'

# Localization
gem 'rails-i18n'

# Pagination
gem 'kaminari'

# Search
gem 'ransack', '~> 4.1'

# Image upload
gem 'carrierwave', '~> 2.0'
gem 'mini_magick'

# ActiveRecord
# 1.5+ で Rails 7.1 に対応（1.4 系は `.import` が ArgumentError になる / #134）
gem 'activerecord-import', '>= 1.5'

# scraping
gem 'open-uri'
gem 'nokogiri'

# google map
gem 'geocoder'
gem 'geokit-rails'

gem 'rexml', '~> 3.2', '>= 3.2.5'

# javascript
gem 'gon'

# Redirection
gem 'open_uri_redirections'

# APIを環境変数化
gem 'dotenv-rails'

# 管理画面
gem "administrate"

# Use Sass to process CSS
gem "sassc-rails"

# SEO
gem 'meta-tags'

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri mingw x64_mingw ]

  # Test
  gem 'factory_bot_rails'
  gem 'rspec-rails'
  gem 'pry-byebug'

  # Code analyse
  gem 'rubocop', require:false
  gem 'rubocop-rails', require:false
  gem 'erb_lint', require: false
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  # gem "rack-mini-profiler"

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  # 3.40+ は selenium-webdriver 4.11+ の Logger 仕様変更に対応している（#134）
  gem "capybara", ">= 3.40"
  gem 'faker'
  gem 'fuubar'
  gem 'shoulda-matchers'
  gem 'timecop'
  # selenium-webdriver 4.11+ bundles Selenium Manager, which resolves the
  # matching chromedriver automatically. The webdrivers gem (Chrome 115+ 非対応)
  # is no longer needed and has been removed (#134).
  gem "selenium-webdriver", ">= 4.11"
end
