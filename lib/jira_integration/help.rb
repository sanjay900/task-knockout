module JiraIntegration
  module Help

    def help_registry
      @help_registry ||= HelpRegistry.new
    end

    class HelpRegistry
      def help_entries
        @help_entries ||= {}
      end

      def add(command, summary, description = "")
        help_entries[command.to_sym] = {summary: summary, description: description}
      end

      def get(command)
        if command && help_entries.has_key?(command)
          ["#{command} #{help_entries[command][:summary]}", help_entries[command][:description]]
        else
          max_length = help_entries.keys.map(&:size).max
          help_entries.map{|k, v| "#{k.to_s.ljust(max_length + 3)} #{v[:summary]}" }
        end
      end
    end
  end
end
