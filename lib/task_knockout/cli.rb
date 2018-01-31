module TaskKnockout
  class CodeRetriever < WEBrick::HTTPServlet::AbstractServlet
    def do_GET(request, response)
      response.status = 200
      @server.shutdown
      code = request.query['code']
      config_file = File.expand_path('../../../config/environments.yml', __FILE__)
      puts code
      github = Github.new TaskKnockout.config[:github]
      TaskKnockout.config[:github][:oauth_token] = github.get_token(code).token
      File.write(config_file, TaskKnockout.config.to_yaml)
    end
  end
  class Cli < Thor
    class_option :format, type: :string, default: 'kv', desc: 'output format for query commands: json, yaml, kv or tp'
    desc 'start <issue_id> [branch name] [--branch-from=develop]', 'Start working on a task.'
    option :branch_from, type: :string, default: 'develop', desc: 'base branch for the branch'
    option :branch_name, type: :string, desc: 'description appended to branch name after its task id'
    def start(issue_id)
      JiraIntegration.api_client.transition(issue_id, 'Start dev')
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
      `git checkout develop`
      `git pull`
      ret = { epic: epic, branch: branch(issue_id) }
      Utils.print_data ret, options
    end

    desc 'stop [branch_from] [--branch_to=develop]', 'stop working on a task. The task is inferred from the current branch,'
    option :branch_from, type: :string, desc: 'the branch to merge'
    option :branch_to, type: :string, default: 'develop', desc: 'the branch to merge into'
    def stop
      branch = `git branch 2> /dev/null`
      issue_id = branch.match(/\* feature\/([A-z0-9]+-[A-z0-9]+)/)
      if issue_id.nil?
        puts 'Unable to infer issue id'
        return
      end
      issue_id = issue_id.captures.first
      puts issue_id
      current = TogglIntegration.api_client.current_entry['data']
      if current.nil?
        puts 'No task was running.'
        return
      end
      id = current['id']
      TogglIntegration.api_client.stop_entry id
      `git push --set-upstream origin #{branch issue_id}`
      pull_request
      JiraIntegration.api_client.transition(issue_id, 'Dev complete')

    end

    desc "branch <issue_id> [branch name] [--branch-from=develop]", "create branch for issue"
    option :branch_from, type: :string, default: "develop", desc: "base branch for ne branch"
    def branch(issue_id, branch_name = nil)
      data = JiraIntegration.api_client.issue issue_id
      key = data.fetch(:key) do
        puts 'issue_id not found'
        exit(1)
      end

      if branch_name
        branch_name = Util.commandify(branch_name)
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

    desc 'setup_github', 'Set up github'
    def setup_github
      github = Github.new TaskKnockout.config[:github]
      puts 'Please navigate to the following url, and then add the code to your configuration file.'
      puts github.authorize_url redirect_uri: 'http://localhost:8123', scope: 'repo'
      # start a local web server to listen to the callback from github's oauth api
      start_server
    end

    desc 'pull_request [issue_id] [branch_from] [--branch_to=develop]', 'Create a pull request for an issue'
    option :branch_from, type: :string, desc: 'the branch to merge'
    option :branch_to, type: :string, default: 'develop', desc: 'the branch to merge into'
    def pull_request
      issue_id = options[:issue_id]
      if issue_id.nil?
        branch = `git branch 2> /dev/null`
        issue_id = branch.match(/\* feature\/([A-z0-9]+-[A-z0-9]+)/).captures.first
      end
      if issue_id.nil?
        puts 'Unable to infer issue id'
        return
      end
      issue = JiraIntegration.api_client.issue issue_id, fields: ['summary']
      branch_name = options[:branch_from]
      branch_name = branch issue_id if branch_name.nil?
      pulls = Github::Client::PullRequests.new TaskKnockout.config[:github]
      repo_name = `git config --get remote.origin.url`
      repo_name = `basename -s .git #{repo_name}`
      repo_name = repo_name.strip!
      body_file = File.expand_path('../../../PULL_REQUEST_TEMPLATE.md', __FILE__)
      body = File.read(body_file)
      body.gsub! 'TM-N', issue_id
      ret = {
        user_name: TaskKnockout.config[:github][:user_name],
        repo_name: repo_name,
        title: "[#{issue_id}] #{issue[:fields][:summary]}",
        body: body,
        head: branch_name,
        base: options[:branch_to]
      }
      Utils.print_data ret, options
      req = pulls.create ret[:user_name], ret[:repo_name],
                         title: ret[:title],
                         body: ret[:body],
                         head: ret[:head],
                         base: ret[:base]
      ret[:url] = req[:_links][:html][:href]
      Utils.print_data ret, options
    end

    private

    def github
      @github ||= Github.new TaskKnockout.config[:github]
    end

    def start_server
      server = WEBrick::HTTPServer.new(Port: 8123)
      server.mount '/', CodeRetriever
      trap 'INT' do server.shutdown end
      server.start
    end
  end
end
