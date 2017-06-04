module JiraIntegration
  class Cli < Thor

    desc "branch <issue_id> [branch name] [--branch-from=develop]", "create branch for issue"
    option :branch_from, type: :string, default: "develop", desc: "base branch for ne branch"
    option :branch_name, type: :string, desc: "description appended to branch name after its task id"
    def branch(issue_id)
      data = JiraIntegration.api_client.issue(issue_id)
      key = data[:key]
      if options[:branch_name]
        branch_name = commandify(options[:branch_name])
        branch_name = "feature/#{key}-#{branch_name}"
      else
        branches = `git branch --no-color -a`.lines.map(&:strip)
        branches = branches.map{|b| b.sub(/^\*\s+/, '').sub(/^remotes\/[^\/]+\//, '') }
        branches = branches.uniq

        search_regexp = Regexp.new("/#{key}-", :i)
        related_branches = branches.grep(search_regexp)

        if related_branches.empty?
          branch_name = data[:fields][:summary]
          branch_name = commandify(branch_name)
          branch_name = "feature/#{key}-#{branch_name}"
        elsif related_branches.size == 1
          branch_name = related_branches.first
        else
          puts "too many found: please, specify branch name."
          puts related_branches.join("\n")
          return
        end
      end
      `git checkout "#{branch_name}" 2>/dev/null || git checkout -b "#{branch_name}" "#{options[:branch_from]}"`
    end

    desc "branches <issue_id>", "list existing branches for issue"
    def branches(issue_id)
      data = JiraIntegration.api_client.issue(issue_id)
      key = data[:key]

      branches = `git branch --no-color -a`.lines.map(&:strip)
      branches = branches.map{|b| b.sub(/^\*\s+/, '').sub(/^remotes\/[^\/]+\//, '') }
      branches = branches.uniq
      search_regexp = Regexp.new("/#{key}-", :i)
      related_branches = branches.grep(search_regexp)

      puts related_branches.join("\n")
    end

    desc "filter <filter_id>", "print filtered issues"
    def filter(filter_id)
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

    desc "filters", "print current user existing filters"
    def filters
      data = JiraIntegration.api_client.my_filters
      # data = data.map{|f| {id: f[:id], name: f[:name], search_url: f[:searchUrl]}, jql: f[:jql]}}
      # puts data.to_yaml
      data = data.map{|f| {id: f[:id], name: f[:name]}}
      tp data
    end

    desc "issue <issue_id>", "print information about specified issue"
    def issue(issue_id)
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

    desc "issue_transitions <issue_id>", "list available transitions for specified issue"
    def issue_transitions(issue_id)
      data = JiraIntegration.api_client.issue_transitions(issue_id)
      data = data[:transitions].map{|f| {id: f[:id], name: f[:name]} }
      puts data.to_yaml
    end

    desc "myself", "print print information about current user"
    def myself
      puts JiraIntegration.api_client.myself.to_yaml
    end

    desc "pull_request <issue_id> [branch_name]", "[NYI] create pull request for issue"
    def pull_request
      branch_name = 'feature/AD-1282-something-done'
      "git push --set-upstream origin '#{branch_name}'"
      "hub pull-request -m 'AD-1282: fix form preview' -b 'develop' -h '#{branch_name}'"
    end

    desc "show_filter", "print information about the informed filter"
    def show_filter(filter_id)
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

    desc "transition <issue_id> <transition id or name>", "transition a issue to another state"
    def transition(issue_id, transition_id)
      if transition_id.match /[a-zA-Z]/
        state_name = commandify(transition_id)
        response = JiraIntegration.api_client.issue_transitions(issue_id)
        matching_transitions = response[:transitions].select{|t| commandify(t[:name]).include?(state_name) }
        if matching_transitions.size == 0
          puts "Could not find matching transition for issue."
          puts "Available transitions:"
          puts response[:transitions].map{|t| t[:name] }.to_yaml
          return
        elsif matching_transitions.size == 1
          transition_id = matching_transitions.first[:id]
        else
          puts "multiple transitions matched, please be more specific"
          puts "matched transitions:"
          puts matching_transitions.map{|t| t[:name] }.to_yaml
          return
        end
      end
      data = JiraIntegration.api_client.transition(issue_id, transition_id)
      puts data.to_yaml
    end

    private

    def commandify(str)
      str.downcase.gsub(/[^a-z0-9]/, '-').gsub(/-+/, '-').gsub(/^-/, '').gsub(/-$/, '')
    end

  end
end
