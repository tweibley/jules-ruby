# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path('lib', __dir__))
require 'jules-ruby'
client = JulesRuby::Client.new # Uses JULES_API_KEY from .env
# List sources
client.sources.all.each { |s| puts s.github_repo.full_name }
# # Create session (update source with a real repo from your account)
# session = client.sessions.create(
#   prompt: "Fix the bug",
#   source_context: { "source" => "sources/github/org/repo", "githubRepoContext" => { "startingBranch" => "main" } }
# )
# # Monitor progress
# client.activities.all(session.name).each { |a| puts "#{a.type}: #{a.progress_title}" }
