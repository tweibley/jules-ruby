# frozen_string_literal: true

require_relative '../prompts'

module JulesRuby
  class Interactive
    # Manages viewing sources
    class SourceManager
      def initialize(client, prompt)
        @client = client
        @prompt = prompt
      end

      def run
        Prompts.clear_screen
        Prompts.print_banner

        sources = fetch_sources
        return if sources.empty?

        source = select_source_to_view(sources)
        return if source == :back

        display_source_details(source)
      end

      private

      def fetch_sources
        sources = Prompts.with_spinner('Loading sources...') { @client.sources.all }
        if sources.empty?
          @prompt.warn(Prompts.rgb_color('No sources found.', :purple))
          @prompt.keypress(Prompts.rgb_color('Press any key to continue...', :dim))
        end
        sources
      end

      def select_source_to_view(sources)
        choices = sources.map { |s| Prompts.format_source_choice(s) }
        choices << { name: "← #{Prompts.rgb_color('Back to main menu', :purple)}", value: :back }

        @prompt.select(
          Prompts.rgb_color('Select a source to view:', :lavender),
          choices,
          filter: true,
          per_page: 15,
          cycle: true
        )
      end

      def display_source_details(source)
        puts
        puts "  #{Prompts.rgb_color('Name:', :lavender)}       #{Prompts.rgb_color(source.name, :purple)}"
        puts "  #{Prompts.rgb_color('ID:', :lavender)}         #{Prompts.rgb_color(source.id, :purple)}"

        repo_label = Prompts.rgb_color('Repository:', :lavender)
        repo_val = Prompts.rgb_color(source.github_repo&.full_name, :purple)
        puts "  #{repo_label} #{repo_val}"
        puts

        @prompt.keypress(Prompts.rgb_color('Press any key to continue...', :dim))
      end
    end
  end
end
