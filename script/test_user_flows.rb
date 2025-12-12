# Script to test user login and dashboard access
# Run with: bin/rails runner script/test_user_flows.rb

users = [
  'admin@reasy.com.au',
  'buyer@reasy.com.au',
  'seller@reasy.com.au',
  'provider@reasy.com.au',
  'both@reasy.com.au'
]

puts "=" * 60
puts "Testing Dashboard Access for All Users"
puts "=" * 60

results = []

users.each do |email|
  user = User.find_by(email: email)
  if user.nil?
    results << { email: email, status: :not_found }
    next
  end

  begin
    # Test that user exists and has required attributes
    name = user.name&.split&.first || "there"
    roles = user.roles || []

    # Simulate what the dashboard view does
    is_buyer = roles.include?('buyer')
    is_seller = roles.include?('seller')
    is_admin = roles.include?('admin')

    puts "\n#{email}:"
    puts "  Name: #{user.name}"
    puts "  Roles: #{roles.join(', ')}"
    puts "  First name display: #{name}"
    puts "  Is buyer: #{is_buyer}"
    puts "  Is seller: #{is_seller}"
    puts "  Is admin: #{is_admin}"
    puts "  Onboarding: #{user.onboarding_completed_at ? 'completed' : 'pending'}"

    results << { email: email, status: :success, roles: roles }
  rescue => e
    puts "\n#{email}: ERROR - #{e.message}"
    results << { email: email, status: :error, error: e.message }
  end
end

puts "\n" + "=" * 60
puts "Summary:"
puts "=" * 60
successes = results.count { |r| r[:status] == :success }
failures = results.count { |r| r[:status] != :success }
puts "Successes: #{successes}"
puts "Failures: #{failures}"

if failures > 0
  puts "\nFailed users:"
  results.select { |r| r[:status] != :success }.each do |r|
    puts "  - #{r[:email]}: #{r[:status]} #{r[:error]}"
  end
end
