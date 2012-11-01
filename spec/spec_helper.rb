require 'rubygems'

RSpec.configure do |config|
  # Integrate flexmock mock gem into rspec
  config.mock_with :flexmock

  # Filter out integration tests
  config.filter_run_excluding :integration => true
end

