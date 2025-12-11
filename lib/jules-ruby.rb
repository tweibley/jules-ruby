# frozen_string_literal: true

require 'dotenv'
Dotenv.load

require_relative 'jules-ruby/version'
require_relative 'jules-ruby/configuration'
require_relative 'jules-ruby/errors'
require_relative 'jules-ruby/client'

# Models
require_relative 'jules-ruby/models/github_repo'
require_relative 'jules-ruby/models/github_branch'
require_relative 'jules-ruby/models/source'
require_relative 'jules-ruby/models/source_context'
require_relative 'jules-ruby/models/session'
require_relative 'jules-ruby/models/pull_request'
require_relative 'jules-ruby/models/plan'
require_relative 'jules-ruby/models/plan_step'
require_relative 'jules-ruby/models/artifact'
require_relative 'jules-ruby/models/activity'

# Resources
require_relative 'jules-ruby/resources/base'
require_relative 'jules-ruby/resources/sources'
require_relative 'jules-ruby/resources/sessions'
require_relative 'jules-ruby/resources/activities'

module JulesRuby
  class << self
    attr_accessor :configuration

    def configure
      self.configuration ||= Configuration.new
      yield(configuration) if block_given?
      configuration
    end

    def reset_configuration!
      self.configuration = Configuration.new
    end
  end
end
