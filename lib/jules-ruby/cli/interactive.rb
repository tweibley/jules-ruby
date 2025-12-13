# frozen_string_literal: true

require_relative 'prompts'
require_relative 'interactive/session_creator'
require_relative 'interactive/session_manager'
require_relative 'interactive/source_manager'

module JulesRuby
  # Interactive mode for jules-ruby CLI
  class Interactive
    def initialize
      @client = JulesRuby::Client.new
      @prompt = Prompts.prompt
    end

    def start
      loop do
        Prompts.clear_screen
        Prompts.print_banner

        choice = main_menu_selection

        case choice
        when :create_session
          SessionCreator.new(@client, @prompt).run
        when :view_sessions
          SessionManager.new(@client, @prompt).run
        when :browse_sources
          SourceManager.new(@client, @prompt).run
        when :exit
          puts Prompts.rgb_color("\nGoodbye! 👋", :purple)
          break
        end
      end
    end

    private

    def main_menu_selection
      @prompt.select(Prompts.rgb_color('What would you like to do?', :lavender), cycle: true) do |menu|
        menu.choice Prompts.rgb_color('Create new session', :purple), :create_session
        menu.choice Prompts.rgb_color('View sessions', :purple), :view_sessions
        menu.choice Prompts.rgb_color('Browse sources', :purple), :browse_sources
        menu.choice Prompts.rgb_color('Exit', :purple), :exit
      end
    end
  end
end
