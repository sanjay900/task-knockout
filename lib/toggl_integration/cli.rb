module TogglIntegration
  class Cli < Thor
    class_option :format, type: :string, default: "kv", desc: "output format for query commands: json, yaml, kv or tp"

    desc "start <description> <project>", "Start a task"
    def start(description, project)
      data = TogglIntegration.api_client.add_entry(description, project)
      Utils.print_data data, options
    end

    desc "workspaces", "List all workspaces"
    def workspaces
      data = TogglIntegration.api_client.workspaces
      Utils.print_data data, options
    end

    desc "projects", "List all projects"
    def projects
      data = TogglIntegration.api_client.projects
      Utils.print_data data, options
    end

    desc 'get', 'Get the current project in progress'
    def get
      data = TogglIntegration.api_client.current_entry
      Utils.print_data data, options
    end

    desc 'stop [id]', 'Stop the current project in progress'
    def stop(id = nil)
      if id.nil?
        current = TogglIntegration.api_client.current_entry['data']
        if current.nil?
          puts 'No task was running.'
          return
        end
        id = current['id']
      end
      data = TogglIntegration.api_client.stop_entry(id)['data']
      data['project'] = TogglIntegration.api_client.project(data['pid'])['name']
      Utils.print_data data, options
    end
  end
end
