module TaskKnockout
  class Cli < Thor
    class_option :format, type: :string, default: "kv", desc: "output format for query commands: json, yaml, kv or tp"
    desc "start <issue_id> [branch name] [--branch-from=develop]", "Start working on a task."
    option :branch_from, type: :string, default: "develop", desc: "base branch for the branch"
    option :branch_name, type: :string, desc: "description appended to branch name after its task id"
    def start(issue_id)
      #JiraIntegration.api_client.transition(issue_id, "Start Dev")
      epic_data = JiraIntegration.api_client.metadata issue_id
      epic_field = nil
      epic_id = nil
      epic_data[:fields].each do |field, f_data|
        # There is a custom field defined, that gets a random id but always has this as its custom
        next unless f_data[:schema][:custom] == 'com.pyxis.greenhopper.jira:gh-epic-link'
        epic_data = JiraIntegration.api_client.issue(issue_id, fields: [field])
        epic_id = epic_data[:fields][field]
        epic_data = JiraIntegration.api_client.metadata epic_id
        epic_data[:fields].each do |field2, f_data2|
          # There is a custom field defined, that gets a random id but always has this as its custom
          next unless f_data2[:schema][:custom] == 'com.pyxis.greenhopper.jira:gh-epic-label'
          epic_field = field2
        end
      end
      if epic_field.nil?
        puts "Unable to find epic link for #{issue_id}"
        return
      end
      data = JiraIntegration.api_client.issue epic_id, fields: [epic_field]
      epic = data[:fields][epic_field]
      data = JiraIntegration.api_client.issue issue_id
      puts "Found epic: #{epic}"
      ret = {:epic => epic}
      fields = data.fetch(:fields) do
        puts "failed to retrieve issue fields"
        exit(1)
      end

      summary = fields.fetch(:summary) do
        puts "failed to retrieve issue summary field"
        exit(1)
      end
      TogglIntegration.api_client.add_entry "[#{issue_id}] - #{summary}", epic
      ret[:branch] = branch(issue_id)
      print_data ret
    end

    desc "branch <issue_id> [branch name] [--branch-from=develop]", "create branch for issue"
    option :branch_from, type: :string, default: "develop", desc: "base branch for the branch"
    option :branch_name, type: :string, desc: "description appended to branch name after its task id"
    def branch(issue_id)
      data = JiraIntegration.api_client.issue issue_id
      key = data.fetch(:key) do
        puts "issue_id not found"
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
            puts "failed to retrieve issue fields"
            exit(1)
          end

          summary = fields.fetch(:summary) do
            puts "failed to retrieve issue summary field"
            exit(1)
          end

          branch_name = summary
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
      branch_name
    end

    desc "branches <issue_id>", "list existing branches for issue"
    def branches(issue_id)
      data_str = Bundler.with_clean_env do
        `jira-cli issue #{issue_id} --format=json 2> /dev/null || echo "{}"`
      end
      data = JSON.parse(data_str, symbolize_names: true)
      key = data.fetch(:key) do
        puts "issue_id not found"
        exit(1)
      end

      branches = `git branch --no-color -a`.lines.map(&:strip)
      branches = branches.map{|b| b.sub(/^\*\s+/, '').sub(/^remotes\/[^\/]+\//, '') }
      branches = branches.uniq
      search_regexp = Regexp.new("/#{key}-", :i)
      related_branches = branches.grep(search_regexp)

      puts related_branches.join("\n")
    end

    desc "pull_request <issue_id> [branch_name]", "[NYI] create pull request for issue"
    def pull_request
      branch_name = 'feature/AD-1282-something-done'
      "git push --set-upstream origin '#{branch_name}'"
      "hub pull-request -m 'AD-1282: fix form preview' -b 'develop' -h '#{branch_name}'"
    end

    private

    def commandify(str)
      str.downcase.gsub(/[^a-z0-9]/, '-').gsub(/-+/, '-').gsub(/^-/, '').gsub(/-$/, '')
    end
    def print_data(data)
      if options[:format] == 'json'
        puts data.to_json
      elsif options[:format] == 'yaml'
        puts data.to_yaml
      elsif options[:format] == 'kv'
        to_kv(data).each do |k, v|
          puts "#{k}: #{v}"
        end
      elsif options[:format] == "tp"
        tp data
      end
    end

    def to_kv(data)
      to_kv_items(nil, data).flatten.reduce({}){|o, i| o.merge i}
    end

    def to_kv_items(root, data)
      if data.respond_to? :each
        if data.respond_to? :has_key?
          join_char = if root && root[-1] != ']'
                        '.'
                      end
          data.map do |k, v|
            to_kv_items([root, k].select{|p| p}.join(join_char), v)
          end
        else
          data.each_with_index.map do |v, i|
            to_kv_items("#{root}[#{i}]", v)
          end
        end
      else
        [{root => data}]
      end
    end
  end
end
