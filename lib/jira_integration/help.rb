module JiraIntegration
  module Help
    def self.entries
      @entries ||= {}
    end

    def self.add(command, summary, description = "")
      entries[command.to_sym] = {summary: summary, description: description}
    end

    def self.get(command)
      if command && entries.has_key?(command)
        ["#{command} #{entries[command][:summary]}", entries[command][:description]]
      else
        max_length = entries.keys.map(&:size).max
        entries.map{|k, v| "#{k.to_s.ljust(max_length + 3)} #{v[:summary]}" }
      end
    end
  end
end
