module JiraIntegration
  module Commands
    extend Help

    help_registry.add(:Usage, "jira-cli <command> [options] [arguments]\n")

    help_registry.add(
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

      puts help_registry.get(command).join("\n")
    end

    help_registry.add(
      :branch,
      "create branch for issue",
      "branch <issue_id> [branch name] [--branch_from=develop]"
    )
    def self.branch(issue_id, branch_name = nil, branch_from: 'develop', **args)
      data = JiraIntegration.api_client.issue(issue_id)
      key = data[:key]
      if branch_name
        branch_name = branch_name.downcase.gsub(/[^a-z0-9]/, '-').gsub(/-+/, '-').gsub(/^-/, '').gsub(/-$/, '')
        branch_name = "feature/#{key}-#{branch_name}"
      else
        branches = `git branch --no-color -a`.lines.map(&:strip)
        branches = branches.map{|b| b.sub(/^\*\s+/, '').sub(/^remotes\/[^\/]+\//, '') }
        branches = branches.uniq

        search_regexp = Regexp.new("/#{key}-", :i)
        related_branches = branches.grep(search_regexp)

        if related_branches.empty?
          branch_name = data[:fields][:summary]
          branch_name = branch_name.downcase.gsub(/[^a-z0-9]/, '-').gsub(/-+/, '-').gsub(/^-/, '').gsub(/-$/, '')
          branch_name = "feature/#{key}-#{branch_name}"
        elsif related_branches.size == 1
          branch_name = related_branches.first
        else
          puts "too many found: please, specify branch name."
          puts related_branches.join("\n")
          return
        end
      end
      `git checkout "#{branch_name}" 2>/dev/null || git checkout -b "#{branch_name}" "#{branch_from}"`
    end

    help_registry.add(
      :branches,
      "list existing branches for issue",
      "branches <issue_id>"
    )
    def self.branches(issue_id, *args)
      data = JiraIntegration.api_client.issue(issue_id)
      key = data[:key]

      branches = `git branch --no-color -a`.lines.map(&:strip)
      branches = branches.map{|b| b.sub(/^\*\s+/, '').sub(/^remotes\/[^\/]+\//, '') }
      branches = branches.uniq
      search_regexp = Regexp.new("/#{key}-", :i)
      related_branches = branches.grep(search_regexp)

      puts related_branches.join("\n")
    end

    help_registry.add(
      :filter,
      "print filtered issues",
      "filter <filter_id>"
    )
    def self.filter(filter_id, *args)
      search = JiraIntegration.api_client.search_by_filter(filter_id)
      # data = search[:issues].map{|i| {id: i[:id], key: i[:key], summary: i[:fields][:summary], description: i[:fields][:description]} }
      # data = search[:issues].map{|i| {id: i[:id], key: i[:key], summary: i[:fields][:summary]} }
      # puts data.to_yaml
      data = search[:issues].map do |i|
        {
          key: i[:key],
          type: i[:fields][:issuetype][:name],
          status: i[:fields][:status][:name],
          summary: i[:fields][:summary],
        }
      end
      tp data, :key, {type: {width: 20}}, {status: {width: 20}}, summary: {width: 130}
    end

    help_registry.add(
      :filters,
      "print current user existing filters",
      "filters"
    )
    def self.filters(*args)
      data = JiraIntegration.api_client.my_filters
      # data = data.map{|f| {id: f[:id], name: f[:name], search_url: f[:searchUrl]}, jql: f[:jql]}}
      # puts data.to_yaml
      data = data.map{|f| {id: f[:id], name: f[:name]}}
      tp data
    end

    help_registry.add(
      :issue,
      "print information about specified issue",
      "issue <issue_id>"
    )
    def self.issue(issue_id, *args)
      issue = JiraIntegration.api_client.issue(issue_id)
      fields = issue[:fields]
      transitions = issue[:transitions]
      data = {
        key: issue[:key],
        summary: fields[:summary],
        issuetype: fields[:issuetype][:name],
        status: fields[:status][:name],
        creator: fields[:creator][:displayName],
        reporter: fields[:reporter][:displayName],
        available_transitions: transitions.map{|t| t[:name] }
      }
      puts data.to_yaml
      puts "description: #{fields[:description]}"
    end

    help_registry.add(
      :issue_transitions,
      "list available transitions for specified issue",
      "issue_transitions <issue_id>"
    )
    def self.issue_transitions(issue_id, *args)
      data = JiraIntegration.api_client.issue_transitions(issue_id)
      data = data[:transitions].map{|f| {id: f[:id], name: f[:name]} }
      puts data.to_yaml
    end

    help_registry.add(
      :myself,
      "print print information about current user",
      "myself"
    )
    def self.myself(*args)
      puts JiraIntegration.api_client.myself.to_yaml
    end

    help_registry.add(
      :show_filter,
      "print information about the informed filter",
      "filters"
    )
    def self.show_filter(filter_id, *args)
      filter = JiraIntegration.api_client.filter(filter_id)
      data = {
        id: filter[:id],
        name: filter[:name],
        owner: filter[:owner][:displayName],
        jql: filter[:jql],
        viewUrl: filter[:viewUrl],
        # searchUrl: filter[:searchUrl],
      }
      puts data.to_yaml
    end

    help_registry.add(
      :transition,
      "transition a issue to another state",
      "transition <issue_id> <state_id>"
    )
    def self.transition(issue_id, state_id, *args)
      data = JiraIntegration.api_client.transition(issue_id, state_id)
      puts data.to_yaml
    end


  end
end
