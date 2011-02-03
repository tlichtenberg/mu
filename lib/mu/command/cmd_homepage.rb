# Api methods to access the Mu System homepage
require 'mu/api/homepage'
class Mu
class Command
class Cmd_homepage < Command

  attr_accessor :host, :username, :password, :api

  # displays command-line help
  #   * argv = command-line arguments
  def cmd_help argv
    help
  end

  # returns all homepage information
  #   * argv = command-line arguments
  def cmd_all argv 
    setup argv
    response = @api.all
    msg response
    return response
  end

  # returns recent homepage information
  #   * argv = command-line arguments
  def cmd_recent argv
    setup argv
    response = @api.recent
    msg response
    return response
  end

  # returns homepage status information
  #   * argv = command-line arguments
  def cmd_status argv
    setup argv
    response = @api.status
    msg response
    return response
  end

  # returns the latest test
  #   * argv = command-line arguments
  def cmd_latest_test argv
    setup argv
    response = @api.latest_test
    msg response
    return response
  end

  # returns the queued tests
  #   * argv = command-line arguments
  def cmd_queue_test argv
    setup argv
    response = @api.queue_test
    msg response
    return response
  end

private
  
  def setup argv
    parse_cli argv
    @host = (@@mu_ip.nil?) ? "127.0.0.1" : @@mu_ip
    @username  = (@@mu_admin_user.nil?) ? "admin" : @@mu_admin_user
    @password  = (@@mu_admin_pass.nil?) ? "admin" : @@mu_admin_pass
    @cookie = ""
    @response = nil
    @api = Homepage.new(@host, @username, @password)
    msg "Created Homepage object to :#{@host}", Logger::DEBUG
  end

  def parse_cli argv
      @hash = {}
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

  def help
        helps = [
            { :short => '-h', :long => '--help', :value => '', :help => 'help on command line options' },
            { :short => '-m', :long => '--mu_string', :value => '<string>', :help => 'user, password, mu_ip in the form of admin:admin@10.9.8.7' },
            { :short => '-o', :long => '--output', :value => '<string>', :help => 'output logging to this file' },
            { :short => '-v', :long => '--verbose', :value => '', :help => 'set Logger::DEBUG level' }
        ]

       cmds = [
          "mu cmd_homepage:all",
          "mu cmd_homepage:help",
          "mu cmd_homepage:latest_test",
          "mu cmd_homepage:queue_test",
          "mu cmd_homepage:recent",
          "mu cmd_homepage:status",
       ]

        max_long_size = helps.inject(0) { |memo, obj| [ obj[:long].size, memo ].max }
        max_value_size = helps.inject(0) { |memo, obj| [ obj[:value].size, memo ].max }
        puts
        puts "Usage: mu cmd_homepage:<command> <options>"
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