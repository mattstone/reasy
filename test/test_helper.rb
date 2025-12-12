# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "mocha/minitest"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Include FactoryBot methods
    include FactoryBot::Syntax::Methods

    # Add more helper methods to be used by all tests here...

    # Helper to enable audit logging in tests when needed
    def with_audit_logging
      Thread.current[:enable_audit_logging] = true
      yield
    ensure
      Thread.current[:enable_audit_logging] = false
    end
  end
end
