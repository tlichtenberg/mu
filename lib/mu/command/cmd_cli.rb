# Api methods to access the Mu CLI calls
class Mu
class Command
class Cmd_cli < Command

  attr_accessor :host, :username, :password, :api

  # displays command-line help
  def cmd_help argv
    help
  end

  # runs the cli help command
  #  * argv = command-line arguments
  def cmd_cli_help argv
    setup argv
    msg run_cmd("help")
  end

  # runs the cli command '?"
  #  * argv = command-line arguments
  def cmd_question argv
    setup argv
    msg run_cmd("?")
  end

  # displays the command line history for the current session
  #  * argv = command-line arguments
  def cmd_history argv
    setup argv
    msg run_cmd("history")
  end

  # pings an ip address
  #  * argv = command-line arguments, requires an ip address (-a) argument
  def cmd_ping argv
    setup argv
    addr = @hash["address"]
    msg run_cmd("ping #{addr}")
  end

  # runs traceroute on an ip address
  #  * argv = command-line arguments, requires an ip address (-a) argument
  def cmd_traceroute argv
    setup argv
    addr = @hash["address"]
    msg run_cmd("traceroute #{addr}")
  end

private

  # runs the cli command
  def run_cmd(command, prompt=@prompt)
    msg "run command #{command}"
    @pipe.write("#{command}\r")
    response = @pipe.readline(prompt)
    @pipe.close
    return response
  end

  def setup argv
    parse_cli argv
    @host = (@@mu_ip.nil?) ? "127.0.0.1" : @@mu_ip
    @username  = (@@mu_admin_user.nil?) ? "admin" : @@mu_admin_user
    @password  = (@@mu_admin_pass.nil?) ? "admin" : @@mu_admin_pass
    @prompt = "MU>"
    @pipe = IO.popen("./lib/mu/cli/muclish.tcl #{@host} #{@password} '#{@prompt}'", 'w+')
    @pipe.sync = true
    @banner = @pipe.readline(@prompt)
  end
  
  def parse_cli argv
      @hash = {}
      args = Array.new
      while not argv.empty?
          args << argv.shift if argv.first[0,1] != '-'

          k = argv.shift

          if [ '-a', '--address' ].member? k
              @hash['address'] = shift(k, argv)
              next
          end

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
            { :short => '-a', :long => '--address', :value => '<string', :help => 'ip address to for ping or traceroute' },
            { :short => '-h', :long => '--help', :value => '', :help => 'Help on command line options' },
            { :short => '-o', :long => '--output', :value => '<string>', :help => 'output logging to this file' },
            { :short => '-m', :long => '--mu_string', :value => '<string>', :help => 'user, password, mu_ip in the form of admin:admin@10.9.8.7' },
            { :short => '-v', :long => '--verbose', :value => '', :help => 'set Logger::DEBUG level' }
        ]

       cmds = [
          "mu cmd_cli:cli_help",
          "mu cmd_cli:history",
          "mu cmd_cli:ping -a <address>",
          "mu cmd_cli:question",
          "mu cmd_cli:traceroute -a <address>",
       ]

        max_long_size = helps.inject(0) { |memo, obj| [ obj[:long].size, memo ].max }
        max_value_size = helps.inject(0) { |memo, obj| [ obj[:value].size, memo ].max }
        puts
        puts "Usage: mu cmd_cli:<command> <options>"
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
