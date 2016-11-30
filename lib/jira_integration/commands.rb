module JiraIntegration
  module Commands
    def self.help(*args)
      puts "myself                      print current user information"
      puts "filters                     print list of filters"
      puts "show_filter <filter_id>     print details of a filter"
      puts "filter <filter_id>          print filtered issues"
      puts "lots to do yet"
    end

    def self.filters(*args)
      filters = JiraIntegration.api_client.my_filters
      # binding.pry
      data = filters.map{|f| {id: f[:id], name: f[:name], search_url: f[:searchUrl]}}
      puts data.to_yaml
    end

    def self.filter(filter_id, *args)
      search = JiraIntegration.api_client.search_by_filter(filter_id)
      # data = search[:issues].map{|i| {id: i[:id], key: i[:key], summary: i[:fields][:summary], description: i[:fields][:description]} }
      data = search[:issues].map{|i| {id: i[:id], key: i[:key], summary: i[:fields][:summary]} }
      puts data.to_yaml
    end

    def self.issue(issue_id, *args)
      issue = JiraIntegration.api_client.issue(issue_id)
      puts issue.to_yaml
    end

    def self.show_filter(filter_id, *args)
      filter = JiraIntegration.api_client.filter(filter_id)
      puts filter.to_yaml
    end

    def self.myself(*args)
      puts JiraIntegration.api_client.myself.to_yaml
    end

  end
end
