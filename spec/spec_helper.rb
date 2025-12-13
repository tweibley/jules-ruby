# frozen_string_literal: true

require 'simplecov'
SimpleCov.start

require 'jules-ruby'
require 'webmock/rspec'

RSpec.configure do |config|
  config.example_status_persistence_file_path = '.rspec_status'
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:each) do
    JulesRuby.reset_configuration!
    JulesRuby.configure do |c|
      c.api_key = 'test_api_key'
    end
  end
end

WebMock.disable_net_connect!
