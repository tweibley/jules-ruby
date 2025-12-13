# frozen_string_literal: true

require_relative 'base'

module JulesRuby
  module Commands
    # Sources subcommand
    class Sources < Base
      desc 'list', 'List all connected repositories'
      long_desc <<~LONGDESC
        List all GitHub repositories connected to your Jules account.

        Examples:
          $ jules-ruby sources list
          $ jules-ruby sources list --format=json
      LONGDESC
      format_option
      def list
        sources = client.sources.all
        if options[:format] == 'json'
          puts JSON.pretty_generate(sources.map(&:to_h))
        else
          print_sources_table(sources)
        end
      rescue JulesRuby::Error => e
        error_exit(e)
      end

      desc 'show NAME', 'Show details for a source'
      long_desc <<~LONGDESC
        Show details for a specific source.

        Example:
          $ jules-ruby sources show sources/github/owner/repo
      LONGDESC
      format_option
      def show(name)
        source = client.sources.find(name)
        if options[:format] == 'json'
          puts JSON.pretty_generate(source.to_h)
        else
          print_source_details(source)
        end
      rescue JulesRuby::Error => e
        error_exit(e)
      end

      private

      def print_sources_table(sources)
        if sources.empty?
          puts 'No sources found.'
          return
        end
        puts 'NAME                                               REPOSITORY          '
        puts '-' * 72
        sources.each do |s|
          puts format('%<name>-50s %<repo>-20s', name: s.name, repo: s.github_repo&.full_name || 'N/A')
        end
      end

      def print_source_details(source)
        puts "Name:       #{source.name}"
        puts "ID:         #{source.id}"
        return unless source.github_repo

        puts "Repository: #{source.github_repo.full_name}"
        puts "URL:        #{source.github_repo.url}" if source.github_repo.respond_to?(:url)
      end
    end
  end
end
