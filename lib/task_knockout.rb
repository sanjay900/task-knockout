module TaskKnockout

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
        # logger.level = Logger.const_get level.upcase
        logger
      end
    end
  end

  def self.api_client
    @api_client ||= ApiClient.new(
      jira_host: config[:jira_host],
      login: config[:login],
      password: config[:password],
      logger: logger,
    )
  end

end

require 'task_knockout/help'
require 'task_knockout/cli'
require 'task_knockout/api_client'
require 'task_knockout/version'
