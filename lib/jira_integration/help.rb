module JiraIntegration
  module Help
    def self.entries
      @entries ||= {}
    end

    def self.add(command, summary, description = "")
      entries[command.to_sym] = {summary: summary, description: description}
    end

    def self.get(command = :help)
      if command == :help
        entries.map{|k, v| "#{k} #{v[:summary]}" }
      else
        ["#{command} #{entries[command][:summary]}", entries[command][:description]]
      end
    end
  end
end
