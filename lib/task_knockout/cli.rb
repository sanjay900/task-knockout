module TaskKnockout
  class Cli < Thor
    class_option :format, type: :string, default: 'kv', desc: 'output format for query commands: json, yaml, kv or tp'
    desc 'start <issue_id> [branch name] [--branch-from=develop]', 'Start working on a task.'
    option :branch_from, type: :string, default: 'develop', desc: 'base branch for the branch'
    option :branch_name, type: :string, desc: 'description appended to branch name after its task id'
    def start(issue_id)
      # JiraIntegration.api_client.transition(issue_id, "Start Dev")
      epic = JiraIntegration.api_client.epic issue_id
      if epic.nil?
        puts "Unable to find epic for #{issue_id}"
        return
      end
      data = JiraIntegration.api_client.issue issue_id
      fields = data.fetch(:fields) do
        puts 'failed to retrieve issue fields'
        exit(1)
      end

      summary = fields.fetch(:summary) do
        puts 'failed to retrieve issue summary field'
        exit(1)
      end
      TogglIntegration.api_client.add_entry "[#{issue_id}] - #{summary}", epic
      ret = { epic: epic, branch: branch(issue_id) }
      Utils.print_data ret, options
    end

    desc 'branch <issue_id> [branch name] [--branch-from=develop]', 'create branch for issue'
    option :branch_from, type: :string, default: 'develop', desc: 'base branch for the branch'
    option :branch_name, type: :string, desc: 'description appended to branch name after its task id'
    def branch(issue_id)
      data = JiraIntegration.api_client.issue issue_id
      key = data.fetch(:key) do
        puts 'issue_id not found'
        exit(1)
      end

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
          fields = data.fetch(:fields) do
            puts 'failed to retrieve issue fields'
            exit(1)
          end

          summary = fields.fetch(:summary) do
            puts 'failed to retrieve issue summary field'
            exit(1)
          end

          branch_name = summary
          branch_name = Utils.commandify(branch_name)
          branch_name = "feature/#{key}-#{branch_name}"
        elsif related_branches.size == 1
          branch_name = related_branches.first
        else
          puts 'too many found: please, specify branch name.'
          puts related_branches.join("\n")
          return
        end
      end
      `git checkout "#{branch_name}" 2>/dev/null || git checkout -b "#{branch_name}" "#{options[:branch_from]}"`
      branch_name
    end

    desc 'branches <issue_id>', 'list existing branches for issue'
    def branches(issue_id)
      data_str = Bundler.with_clean_env do
        `jira-cli issue #{issue_id} --format=json 2> /dev/null || echo "{}"`
      end
      data = JSON.parse(data_str, symbolize_names: true)
      key = data.fetch(:key) do
        puts 'issue_id not found'
        exit(1)
      end

      branches = `git branch --no-color -a`.lines.map(&:strip)
      branches = branches.map{|b| b.sub(/^\*\s+/, '').sub(/^remotes\/[^\/]+\//, '') }
      branches = branches.uniq
      search_regexp = Regexp.new("/#{key}-", :i)
      related_branches = branches.grep(search_regexp)

      puts related_branches.join("\n")
    end

    desc 'pull_request <issue_id> [branch_name]', '[NYI] create pull request for issue'
    def pull_request
      branch_name = 'feature/AD-1282-something-done'
      `git push --set-upstream origin '#{branch_name}'`
      `hub pull-request -m 'AD-1282: fix form preview' -b 'develop' -h '#{branch_name}'`
    end

    private
  end
end
