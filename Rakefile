# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new

task default: %i[spec rubocop]

namespace :release do
  desc 'Bump patch version, commit, tag, and push'
  task :patch do
    bump_version(:patch)
  end

  desc 'Bump minor version, commit, tag, and push'
  task :minor do
    bump_version(:minor)
  end

  desc 'Bump major version, commit, tag, and push'
  task :major do
    bump_version(:major)
  end
end

def bump_version(type)
  gemspec_file = 'jules-ruby.gemspec'
  content = File.read(gemspec_file)

  # Extract current version
  version_match = content.match(/spec\.version\s*=\s*["'](\d+)\.(\d+)\.(\d+)["']/)
  unless version_match
    puts 'Could not find version in gemspec'
    exit 1
  end

  major, minor, patch = version_match[1..3].map(&:to_i)

  # Bump version based on type
  case type
  when :major
    major += 1
    minor = 0
    patch = 0
  when :minor
    minor += 1
    patch = 0
  when :patch
    patch += 1
  end

  new_version = "#{major}.#{minor}.#{patch}"
  puts "Bumping version to #{new_version}"

  # Update gemspec
  new_content = content.sub(/spec\.version\s*=\s*["']\d+\.\d+\.\d+["']/, "spec.version       = \"#{new_version}\"")
  File.write(gemspec_file, new_content)

  # Git operations
  sh "git add #{gemspec_file}"
  sh "git commit -m 'Bump version to #{new_version}'"
  sh "git tag v#{new_version}"
  sh 'git push origin main'
  sh "git push origin v#{new_version}"

  puts "Released v#{new_version}!"
end
