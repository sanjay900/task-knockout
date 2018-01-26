module TogglIntegration

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
    toggl = config[:toggl]
    @api_client ||= ApiClient.new(
      workspace: toggl[:workspace],
      api_token: toggl[:api_token],
      logger: logger,
    )
  end

end

require 'toggl_integration/cli'
require 'toggl_integration/api_client'
require 'toggl_integration/version'
