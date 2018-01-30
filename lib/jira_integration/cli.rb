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
      Utils.print_data data, options
    end

    desc "filters", "print current user existing filters"
    def filters
      data = JiraIntegration.api_client.my_filters
      # data = data.map{|f| {id: f[:id], name: f[:name], search_url: f[:searchUrl]}, jql: f[:jql]}}
      # puts data.to_yaml
      # data = data.map{|f| {id: f[:id], name: f[:name]}}
      # tp data
      Utils.print_data data, options
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
      Utils.print_data issue, options
    end

    desc "issue_transitions <issue_id>", "list available transitions for specified issue"
    def issue_transitions(issue_id)
      data = JiraIntegration.api_client.issue_transitions(issue_id)
      data = data[:transitions].map{|f| {id: f[:id], name: f[:name]} }
      Utils.print_data data, options
    end

    desc "myself", "print print information about current user"
    def myself
      data = JiraIntegration.api_client.myself
      # puts `echo '#{data.to_json}' | jq .`
      Utils.print_data data, options
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
      Utils.print_data data, options
    end

    desc "transition <issue_id> <transition id or name>", "transition a issue to another state"
    def transition(issue_id, transition_id)
      data = JiraIntegration.api_client.transition(issue_id, transition_id)
      Utils.print_data data, options
    end
  end
end
