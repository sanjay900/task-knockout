module JiraIntegration
  class ApiClient

    attr_accessor :jira_host, :login, :password

    def initialize(jira_host:, login:, password:)
      self.jira_host = jira_host
      self.login = login
      self.password = password
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

    def issue(id)
      resource = build_resource('api/2/issue', id)
      response = resource.get
      JSON.parse(response.body, symbolize_names: true)
    end

    def issue_transitions(id)
      resource = build_resource('api/2/issue', id, 'transitions')
      response = resource.get
      JSON.parse(response.body, symbolize_names: true)
    end

    def transition(issue_id, state_id)
      resource = build_resource('api/2/issue', issue_id, 'transitions')
      response = resource.post({transition: {id: state_id}}.to_json, content_type: :json)
      if response.code == 204
        true
      else
        JSON.parse(response.body, symbolize_names: true)
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
        }
      )
      response = resource.get
      JSON.parse(response.body, symbolize_names: true)
    end

    def build_resource(*resource_path)
      RestClient::Resource.new(
        resource_url(*resource_path),
        headers: {
          "Authorization" => "Basic #{credentials}"
        }
      )
    end

    def credentials
      Base64.encode64 "#{login}:#{password}"
    end

  end
end
