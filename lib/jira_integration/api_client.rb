module JiraIntegration
  class ApiClient

    attr_accessor :jira_host, :login, :password, :logger

    def initialize(jira_host:, login:, password:, logger:)
      self.jira_host = jira_host
      self.login = login
      self.password = password
      self.logger = logger
    end

    def jira_url
      File.join('https://', "#{jira_host}", 'rest')
    end

    def resource_url(*resource_path)
      File.join(jira_url, *resource_path.flatten)
    end

    def filter(id)
      resource = build_resource('api/2/filter', id)
      response = resource.get
      JSON.parse(response.body, symbolize_names: true)
    end

    def issue(id, fields: [], expand: [])
      resource = build_resource('api/2/issue', id)
      response = resource.get(
        params: {
          fields: fields.join(','),
          expand: expand.join(','),
        }.select{|k, v| v},
      )
      JSON.parse(response.body, symbolize_names: true)
    end

    def metadata(id)
      resource = build_resource('api/2/issue', id, 'editmeta')
      response = resource.get()
      JSON.parse(response.body, symbolize_names: true)
    end

    def issue_transitions(id)
      resource = build_resource('api/2/issue', id, 'transitions')
      response = resource.get
      JSON.parse(response.body, symbolize_names: true)
    end

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
      resource = build_resource('api/2/issue', issue_id, 'transitions')
      response = resource.post({transition: {id: transition_id}}.to_json, content_type: :json)
      if response.code == 204
        true
      else
        JSON.parse(response.body, symbolize_names: true)
      end
    end

    def epic(issue_id)
      # We need to find the epic name
      epic_field = custom_field issue_id, 'com.pyxis.greenhopper.jira:gh-epic-link'
      custom_field epic_field, 'com.pyxis.greenhopper.jira:gh-epic-label'
    end

    def custom_field(issue_id, key)
      data = JiraIntegration.api_client.metadata issue_id
      data[:fields].each do |field, f_data|
        next unless f_data[:schema][:custom] == key
        epic_data = JiraIntegration.api_client.issue(issue_id, fields: [field])
        return epic_data[:fields][field]
      end
    end

    def my_filters
      resource = build_resource('api/2/filter', 'my')
      response = resource.get
      JSON.parse(response.body, symbolize_names: true)
    end

    def myself
      resource = build_resource('api/2/myself')
      response = resource.get
      JSON.parse(response.body)
    end

    def search_by_filter(filter_id)
      filter = filter(filter_id)

      resource = RestClient::Resource.new(
        filter[:searchUrl],
        headers: {
          "Authorization" => "Basic #{credentials}"
        },
        log: logger,
      )
      response = resource.get
      JSON.parse(response.body, symbolize_names: true)
    end

    def build_resource(*resource_path)
      RestClient::Resource.new(
        resource_url(*resource_path),
        headers: {
          "Authorization" => "Basic #{credentials}"
        },
        log: logger,
      )
    end

    def credentials
      Base64.encode64 "#{login}:#{password}"
    end
    def commandify(str)
      str.downcase.gsub(/[^a-z0-9]/, '-').gsub(/-+/, '-').gsub(/^-/, '').gsub(/-$/, '')
    end
  end
end
