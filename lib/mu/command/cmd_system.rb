# Api methods to access the Mu System System page
require 'mu/api/system'
class Mu
class Command
class Cmd_system < Command

  attr_accessor :host, :username, :password, :api

  # outputs help for this command
  def cmd_help argv
    help
  end

  # restarts the Mu System
  #   * array of command-line arguments
  def cmd_restart argv
    setup argv
    response = @api.restart
    msg response
    return response
  end

  # gets basic system status
  #   * array of command-line arguments
  def cmd_status argv
    setup argv
    response = @api.status
    msg response
    return response
  end

  # gets additional system status
  #   * array of command-line arguments
  def cmd_status2 argv
    setup argv
    response = @api.status2
    msg response
    return response
  end

private

  def setup argv
    parse_cli argv
    @host = (@@mu_ip.nil?) ? "127.0.0.1" : @@mu_ip
    @username  = (@@mu_admin_user.nil?) ? "admin" : @@mu_admin_user
    @password  = (@@mu_admin_pass.nil?) ? "admin" : @@mu_admin_pass
    @api = System.new(@host, @username, @password)
    msg "Created System Api object to :#{@host}", Logger::DEBUG
  end


  # parses command-line arguments
  def parse_cli argv
      args = Array.new
      while not argv.empty?
          args << argv.shift if argv.first[0,1] != '-'

          k = argv.shift

          if [ '-h', '--help' ].member? k
            help
            exit
          end

          if [ '-m', '--mu_string' ].member? k
             mu_string = shift(k, argv)
             if mu_string =~ /(.+?):(.+?)@(.*)/
               @@mu_admin_user = $1
               @@mu_admin_pass = $2
               @@mu_ip = $3
             end
             next
          end

          if [ '-o', '--output' ].member? k
            $stdout.reopen(shift(k, argv), "w")
            next
          end

          if [ '-v', '--verbose' ].member? k
            $log.level = Logger::DEBUG
            next
          end

      end

      args
  end

  # displays command-line help
  def help
        helps = [
            { :short => '-h', :long => '--help', :value => '', :help => 'help on command line options' },
            { :short => '-m', :long => '--mu_string', :value => '<string>', :help => 'user, password, mu_ip in the form of admin:admin@10.9.8.7' },
            { :short => '-o', :long => '--output', :value => '<string>', :help => 'output logging to this file' },
            { :short => '-v', :long => '--verbose', :value => '', :help => 'set Logger::DEBUG level' }
        ]

       cmds = [
          "mu cmd_system:restart",
          "mu cmd_system:status",
          "mu cmd_system:status2"
       ]

        max_long_size = helps.inject(0) { |memo, obj| [ obj[:long].size, memo ].max }
        max_value_size = helps.inject(0) { |memo, obj| [ obj[:value].size, memo ].max }
        puts
        puts "Usage: mu cmd_system <options>"
        puts
        helps.each do |h|
            puts "%-*s %*s %-*s %s" % [max_long_size, h[:long], 2, h[:short], max_value_size, h[:value], h[:help]]
        end
        puts
        puts "Available Commands"
        puts
        cmds.each do | c |
           puts c
        end
        puts
    end

end
end # Command
end # Mu