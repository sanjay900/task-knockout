module JiraIntegration

  def self.config=(value)
    @config = value
  end

  def self.config
    @config
  end

  def self.api_client
    @api_client ||= ApiClient.new(
      jira_host: config[:jira_host],
      login: config[:login],
      password: config[:password],
    )
  end

end

require 'jira_integration/api_client'
require 'jira_integration/cli'
require 'jira_integration/commands'
require 'jira_integration/version'
