module JiraIntegration
  class Cli < Thor
    class_option :format, type: :string, default: "kv", desc: "output format for query commands: json, yaml, kv or tp"

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
      # tp data, :key, {type: {width: 20}}, {status: {width: 20}}, summary: {width: 130}
      print_data data
    end

    desc "filters", "print current user existing filters"
    def filters
      data = JiraIntegration.api_client.my_filters
      # data = data.map{|f| {id: f[:id], name: f[:name], search_url: f[:searchUrl]}, jql: f[:jql]}}
      # puts data.to_yaml
      # data = data.map{|f| {id: f[:id], name: f[:name]}}
      # tp data
      print_data data
    end

    desc "issue <issue_id>", "print information about specified issue"
    def issue(issue_id)
      issue = JiraIntegration.api_client.issue(issue_id,
        fields: ['summary', 'description', 'issuetype', 'created', 'status', 'creator', 'reporter', 'transitions'],
        expand: ['transitions'],
      )
      fields = issue[:fields]
      transitions = issue[:transitions]
      # data = {
      #   key: issue[:key],
      #   summary: fields[:summary],
      #   issuetype: fields[:issuetype][:name],
      #   status: fields[:status][:name],
      #   creator: fields[:creator][:displayName],
      #   reporter: fields[:reporter][:displayName],
      #   available_transitions: transitions.map{|t| t[:name] }
      # }
      # puts data.to_yaml
      # puts "description: #{fields[:description]}"
      print_data(issue)
    end

    desc "issue_transitions <issue_id>", "list available transitions for specified issue"
    def issue_transitions(issue_id)
      data = JiraIntegration.api_client.issue_transitions(issue_id)
      data = data[:transitions].map{|f| {id: f[:id], name: f[:name]} }
      print_data(data)
    end

    desc "myself", "print print information about current user"
    def myself
      data = JiraIntegration.api_client.myself
      # puts `echo '#{data.to_json}' | jq .`
      print_data data
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
      print_data data
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
      print_data data
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
