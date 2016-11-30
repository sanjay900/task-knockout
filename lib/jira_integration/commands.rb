module JiraIntegration
  module Commands
    Help.add(:Usage, "jira-cli <command> [options] [arguments]\n")

    JiraIntegration::Help.add(
      :help,
      "print help information",
      "help [command]"
    )
    def self.help(*args)
      command = args.first
      if ! command || command.empty?
        command = nil
      else
        command = command.to_sym
      end

      puts JiraIntegration::Help.get(command).join("\n")
    end

    JiraIntegration::Help.add(
      :branch,
      "create branch for issue",
      "branch <issue_id> [branch name] [--branch_from=develop]"
    )
    def self.branch(issue_id, branch_name = nil, branch_from: 'develop', **args)
      data = JiraIntegration.api_client.issue(issue_id)
      key = data[:key]
      branch_name ||= data[:fields][:summary]
      branch_name = branch_name.downcase.gsub(/[^a-z0-9]/, '-').gsub(/-+/, '-').gsub(/^-/, '').gsub(/-$/, '')
      `git checkout -B "feature/#{key}-#{branch_name}" "#{branch_from}"`
    end

    JiraIntegration::Help.add(
      :branches,
      "list existing branches for issue",
      "branches <issue_id>"
    )
    def self.branches(issue_id, *args)
      data = JiraIntegration.api_client.issue(issue_id)
      key = data[:key]
      puts `git branch -a | grep -i '#{key}'`
    end

    JiraIntegration::Help.add(
      :filter,
      "print filtered issues",
      "filter <filter_id>"
    )
    def self.filter(filter_id, *args)
      search = JiraIntegration.api_client.search_by_filter(filter_id)
      # data = search[:issues].map{|i| {id: i[:id], key: i[:key], summary: i[:fields][:summary], description: i[:fields][:description]} }
      data = search[:issues].map{|i| {id: i[:id], key: i[:key], summary: i[:fields][:summary]} }
      puts data.to_yaml
    end

    JiraIntegration::Help.add(
      :filters,
      "print current user existing filters",
      "filters"
    )
    def self.filters(*args)
      filters = JiraIntegration.api_client.my_filters
      data = filters.map{|f| {id: f[:id], name: f[:name], search_url: f[:searchUrl]}}
      puts data.to_yaml
    end

    JiraIntegration::Help.add(
      :issue,
      "print inrmations about specified issue",
      "issue <issue_id>"
    )
    def self.issue(issue_id, *args)
      data = JiraIntegration.api_client.issue(issue_id)
      puts data.to_yaml
    end

    JiraIntegration::Help.add(
      :myself,
      "print print information about current user",
      "myself"
    )
    def self.myself(*args)
      puts JiraIntegration.api_client.myself.to_yaml
    end

    JiraIntegration::Help.add(
      :show_filter,
      "print information about the informed filter",
      "filters"
    )
    def self.show_filter(filter_id, *args)
      filter = JiraIntegration.api_client.filter(filter_id)
      puts filter.to_yaml
    end

  end
end
