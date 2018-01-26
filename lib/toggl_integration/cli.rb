module TogglIntegration
  class Cli < Thor
    class_option :format, type: :string, default: "kv", desc: "output format for query commands: json, yaml, kv or tp"

    desc "start <description> <project>", "Start a task"
    def start(description, project)
      data = TogglIntegration.api_client.add_entry(description, project)
      print_data data
    end

    desc "workspaces", "List all workspaces"
    def workspaces
      data = TogglIntegration.api_client.workspaces
      print_data data
    end

    desc "projects", "List all projects"
    def projects
      data = TogglIntegration.api_client.projects
      print_data data
    end

    desc 'get', 'Get the current project in progress'
    def get
      data = TogglIntegration.api_client.current_entry
      print_data data
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
          join_char = ('.' if root && root[-1] != ']')
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
