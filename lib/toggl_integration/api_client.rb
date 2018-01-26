module TogglIntegration
  class ApiClient

    attr_accessor :workspace, :api_token, :logger, :workspace_id, :project_list, :project_id_list

    def initialize(workspace:, api_token:, logger:)
      self.workspace = workspace
      self.api_token = api_token
      self.logger = logger
      self.workspace_id = workspaces.find { |w| w['name'] == workspace }['id']
      self.project_list = Hash[projects.map { |p| [p['name'], p] }.to_a]
      self.project_id_list = Hash[projects.map { |p| [p['id'], p] }.to_a]
    end

    def toggl_url
      'https://www.toggl.com'
    end

    def resource_url(*resource_path)
      File.join(toggl_url, *resource_path.flatten)
    end

    def myself
      resource = build_resource('api/v8/me')
      response = resource.get
      JSON.parse(response.body)
    end

    def add_entry(description, project)
      map = {
        time_entry: {
          description: description,
          billable: true,
          start: Time.now.getutc.strftime('%Y-%m-%dT%H:%M:%S.%LZ'),
          pid: project_list[project]['id'],
          created_with: 'Toggl Integration'
        }
      }
      resource = build_resource('api/v8/time_entries/start')
      response = resource.post map.to_json
      JSON.parse(response.body)
    end

    def current_entry
      resource = build_resource('api/v8/time_entries/current')
      response = resource.get
      JSON.parse(response.body)
    end

    def stop_entry(entry_id)
      resource = build_resource("api/v8/time_entries/#{entry_id}/stop")
      response = resource.get
      JSON.parse(response.body)
    end

    def projects
      resource = build_resource("api/v8/workspaces/#{workspace_id}/projects")
      response = resource.get
      JSON.parse(response.body)
    end

    def workspaces
      resource = build_resource('api/v8/workspaces')
      response = resource.get
      JSON.parse(response.body)
    end

    def project(pid)
      project_id_list[pid]
    end

    def build_resource(*resource_path)
      RestClient::Resource.new(
        resource_url(*resource_path),
        headers: {
          'Content-Type' => 'application/json',
          :Authorization => "Basic #{credentials}"
        },
        log: logger,
      )
    end

    def credentials
      Base64.encode64 "#{api_token}:api_token"
    end

  end
end
