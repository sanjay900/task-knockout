module JiraIntegration
  class Cli
    def self.run(*args)
      new(*args).run
    end

    attr_accessor :raw_args, :command, :args, :named_args

    def initialize(*raw_args)
      self.raw_args = raw_args
      parse_arguments
    end

    def parse_arguments
      self.command = command_from_raw_args
      self.named_args = named_args_from_raw_args
      self.args = args_from_raw_args
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

    def args_from_raw_args
      raw_args[1..-1].grep(/^[^-]/)
    end

    def named_args_from_raw_args
      Hash[raw_args[1..-1].grep(/^-/).map{|a| a.sub(/^--/, '').gsub(/-/, '_').split('=').tap{|i| i[0] = i[0].to_sym} }]
    end

    def run
      Commands.send(command, *args, **named_args)
    end
  end
end
