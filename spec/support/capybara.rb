Capybara.register_driver :screenshot_desktop do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument("--headless=new")
  options.add_argument("--window-size=1280,800")
  options.add_argument("--no-sandbox")
  options.add_argument("--disable-dev-shm-usage")
  Capybara::Selenium::Driver.new(app, browser: :chrome, options:)
end

Capybara.register_driver :screenshot_mobile do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument("--headless=new")
  options.add_argument("--window-size=390,844")
  options.add_argument("--no-sandbox")
  options.add_argument("--disable-dev-shm-usage")
  Capybara::Selenium::Driver.new(app, browser: :chrome, options:)
end

Capybara.save_path = Rails.root.join("screenshots")
