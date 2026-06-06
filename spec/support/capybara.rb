# Capybara / Selenium 設定。
#
# CI（GitHub Actions の Chrome for Testing）でもローカルでも同じ headless Chrome で
# system spec を回せるように、ドライバを明示的に登録する。
# selenium-webdriver 4.11+ の Selenium Manager が chromedriver を自動解決するため、
# webdrivers gem は不要（#134）。
require 'capybara/rspec'
require 'selenium-webdriver'

Capybara.register_driver :headless_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless=new')
  # CI のコンテナ / 非特権環境で必須のフラグ
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--disable-gpu')
  options.add_argument('--window-size=1400,1400')

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end
