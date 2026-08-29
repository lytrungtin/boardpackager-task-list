# Force, not default. With ||=, a container that already exports
# RAILS_ENV=development would run the whole suite against the development
# environment and database, and still report green.
ENV["RAILS_ENV"] = "test"
require_relative "../config/environment"
abort "Tests must run in the test environment" unless Rails.env.test?
require "rails/test_help"
require_relative "test_helpers/session_test_helper"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

module ActionDispatch
  class IntegrationTest
    include SessionTestHelper
  end
end
