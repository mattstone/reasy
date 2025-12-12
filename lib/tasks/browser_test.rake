# frozen_string_literal: true

# Only load in development/test environments - exit early in production
# This prevents the file from requiring development gems like capybara/selenium
if defined?(Rails) && !Rails.env.local?
  # Define empty namespace to prevent rake errors if task is referenced
  namespace(:browser_test) { }
  return
end

namespace :browser_test do
  desc "Run comprehensive browser tests for all authenticated user flows"
  task all: :environment do
    puts "\n" + "=" * 60
    puts "Browser Testing All User Flows"
    puts "=" * 60

    # Check if seed users exist
    users = {
      admin: "admin@reasy.com.au",
      buyer: "buyer@reasy.com.au",
      seller: "seller@reasy.com.au",
      provider: "provider@reasy.com.au",
      both: "both@reasy.com.au"
    }

    missing = users.select { |_role, email| User.find_by(email: email).nil? }
    if missing.any?
      puts "\n[ERROR] Missing seed users: #{missing.values.join(', ')}"
      puts "Run: bin/rails db:seed"
      exit 1
    end

    puts "\n[OK] All seed users found"
    puts "\nRunning system tests for authenticated flows..."
    puts "-" * 60

    # Run the specific test file
    system("PARALLEL_WORKERS=1 bin/rails test test/system/authenticated_flows_test.rb")

    exit_code = $?.exitstatus

    puts "\n" + "=" * 60
    if exit_code == 0
      puts "[SUCCESS] All browser tests passed!"
    else
      puts "[FAILURE] Some tests failed. See output above."
    end
    puts "=" * 60

    exit exit_code
  end

  desc "Quick check - verify dashboard loads for all user types"
  task quick: :environment do
    require "capybara"
    require "capybara/dsl"
    require "selenium-webdriver"

    Capybara.register_driver :headless_chrome do |app|
      options = Selenium::WebDriver::Chrome::Options.new
      options.add_argument("--headless=new")
      options.add_argument("--no-sandbox")
      options.add_argument("--disable-gpu")
      options.add_argument("--window-size=1400,1400")

      Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
    end

    Capybara.default_driver = :headless_chrome
    Capybara.app = Rails.application

    include Capybara::DSL

    users = [
      { email: "admin@reasy.com.au", role: "admin" },
      { email: "buyer@reasy.com.au", role: "buyer" },
      { email: "seller@reasy.com.au", role: "seller" },
      { email: "provider@reasy.com.au", role: "provider" },
      { email: "both@reasy.com.au", role: "both" }
    ]

    puts "\n" + "=" * 60
    puts "Quick Browser Check - Dashboard Access"
    puts "=" * 60

    results = []

    users.each do |user_info|
      user = User.find_by(email: user_info[:email])
      unless user
        results << { role: user_info[:role], status: :skip, message: "User not found" }
        next
      end

      begin
        visit "/users/sign_in"
        fill_in "Email", with: user_info[:email]
        fill_in "Password", with: "password123"
        click_button "Log in"

        if page.has_text?("Welcome back", wait: 5)
          results << { role: user_info[:role], status: :pass, message: "Dashboard OK" }
        else
          results << { role: user_info[:role], status: :fail, message: "Missing 'Welcome back'" }
        end

        # Logout for next test
        visit "/users/sign_out" if page.has_button?("Log out")
      rescue StandardError => e
        results << { role: user_info[:role], status: :fail, message: e.message[0..50] }
      end
    end

    puts "\nResults:"
    puts "-" * 60
    results.each do |r|
      icon = case r[:status]
             when :pass then "[PASS]"
             when :fail then "[FAIL]"
             else "[SKIP]"
             end
      puts "#{icon} #{r[:role].upcase.ljust(10)} - #{r[:message]}"
    end

    failures = results.count { |r| r[:status] == :fail }
    puts "-" * 60
    puts failures.zero? ? "[SUCCESS] All checks passed" : "[FAILURE] #{failures} check(s) failed"
    puts "=" * 60

    exit(failures.zero? ? 0 : 1)
  end
end
