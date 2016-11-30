module JiraIntegration
  class Cli
    def self.run(*args)
      new(*args).run
    end

    attr_accessor :raw_args, :command, :list_args, :named_args

    def initialize(*raw_args)
      self.raw_args = raw_args
      parse_arguments
    end

    def parse_arguments
      self.command = command_from_raw_args
      self.named_args = named_args_from_raw_args
      self.list_args = list_args_from_raw_args
    end

    def command_from_raw_args
      command = raw_args.first
      command &&= command.to_sym
      command &&= (valid_commands & [command]).first
      command ||= :help
    end

    def valid_commands
      Commands.methods(false)
    end

    def list_args_from_raw_args
      args.grep(/^[^-]/)
    end

    def named_args_from_raw_args
      Hash[args.grep(/^-/).map{|a| a.sub(/^--/, '').gsub(/-/, '_').split('=').tap{|i| i[0] = i[0].to_sym} }]
    end

    def args
      raw_args[1..-1] || []
    end

    def run
      Commands.send(command, *list_args, **named_args)
    end
  end
end
