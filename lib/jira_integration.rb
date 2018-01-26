module JiraIntegration

  def self.config=(value)
    @config = value
  end

  def self.config
    @config
  end

  def self.logger
    @logger ||= begin
      if config[:logger] && ! config[:logger].empty?
        level = config[:logger][:level] || :debug
        file_id = config[:logger].fetch(:file) { :stdout }
        file = if file_id == :stdout
          STDOUT
        else
          File.join(File.expand_path("../..", __FILE__), file_id)
        end
        logger = Logger.new file
        logger.level = Logger.const_get level.upcase
        logger
      end
    end
  end

  def self.api_client
    jira_config = config[:jira]
    @api_client ||= ApiClient.new(
      jira_host: jira_config[:jira_host],
      login: jira_config[:login],
      password: jira_config[:password],
      logger: logger,
    )
  end

end

require 'jira_integration/cli'
require 'jira_integration/api_client'
require 'jira_integration/version'
