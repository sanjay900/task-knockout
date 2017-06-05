module TaskKnockout
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

  end
end
