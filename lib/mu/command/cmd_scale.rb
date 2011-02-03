# Use these commands to access the legacy REST API for Scale test (Studio Scale). 
require 'mu/api/scale'
class Mu
class Command
class Cmd_scale < Command

  attr_accessor :host, :username, :password, :api

  # outputs help for this command
  def cmd_help argv
    help
  end

  # configures the scale json object
  #  * argv = command-line arguments, requires a params (-p) and params value (-pv) argument, such as -p volume -pv 100
  def cmd_configure argv   
    setup argv
    param = @hash['params']
    value = @hash['param_value']
    response = @api.configure(param, value)
    msg response
    return response
  end

  # starts a scale test
  #  * argv = command-line arguments, requires a scale json object to have been configured
  def cmd_start argv
    setup argv
    response = @api.start
    msg response
    return response
  end

  # verifies a scale test
  #  * argv = command-line arguments, requires a scale json object to have been configured
  def cmd_verify argv
    setup argv
    response = @api.verify
    msg response
    return response
  end

  # updates a running scale test (valid only if the test is running with no pattern)
  #   * argv = command-line arguments, requires a json params object (-p) such as '{ "volume": 100 }'
  def cmd_update argv
    setup argv
    params = @hash['params']
    response = @api.update(params)
    msg response
    return response
  end

  # returns status from a scale test
  #  * argv = command-line arguments
  def cmd_status argv
    setup argv
    response = @api.status
    msg response
    return response
  end

  # returns an array of currently reserved scale engines
  #  * argv = command-line arguments
  def cmd_list argv
    setup argv
    response = @api.list
    msg response
    return response
  end

  # returns scale engine configuration information
  #  * argv = command-line arguments
  def cmd_about argv
    setup argv
    response = @api.about
    msg response
    return response
  end

  # returns a packet capture file from scale verify
  #  * argv = command-line arguments, requires a scale engine id (-b) and the pcap filename (-f) argument
  def cmd_pcap argv
    setup argv
    bot_id = @hash['bot_id']
    file = @hash['filename']
    response = @api.pcap(bot_id, file)
    msg response
    return response
  end

  # returns the status of all reserved scale engines
  #  * argv = command-line arguments
  def cmd_statuses argv
    setup argv
    response = @api.statuses
    msg response
    return response
  end

  # returns scale test data for charting
  #   * argv = command-line arguments, requires:
  #   * view (-w), which specifies the TIMELINE or CALLGRAPH chart.
  #   * zoom (-z), which  specifies the zoom level (0 to 1). 1 returns data for 100% of the time range, 0.5 returns data for 50% of the time range, and 0 returns only the last minute of data
  #   * position (-p), which must be 0.
  #   * scale engine id (-b)
  def cmd_data argv
    setup argv
    begin
      view = @hash['view']
      zoom = @hash['zoom']
      position = @hash['view_position']
      bot_id = @hash['bot_id']
      response = @api.data(view, zoom, position, bot_id)
    rescue => e
      msg e
    end
    msg response
    return response
  end

  # returns scale test data for charting
  #  * argv = command-line arguments, requires:
  #  * zoom (z) level
  #  * position(-p 0)
  def cmd_pattern argv
    setup argv
    begin
      zoom = @hash['zoom']
      position = @hash['view_position']
      response = @api.pattern(zoom, position)
    rescue => e
      msg e
    end
    msg response
    return response
  end

  # stops a scale test
  #  * argv = command-line arguments
  def cmd_stop argv
    setup argv
    response = @api.stop
    msg response
    return response
  end

  # releases the currently reserved scale engine
  #  * argv = command-line arguments
  def cmd_release argv
    setup argv
    response = @api.release
    msg response
    return response
  end

  # reserves a scale engine
  #   * argv = command-line arguments, require a scale engine id (-b) argument
  def cmd_reserve_scale_engine argv
    setup argv
    bot_id = @hash['bot_id']
    response = @api.reserve_scale_engine(bot_id)
    msg response
    return response
  end

  # releases a scale engine
  #   * argv = command-line arguments, require a scale engine id (-b) argument
  def cmd_release_scale_engine argv
   setup argv
    bot_id = @hash['bot_id']
    response = @api.release_scale_engine(bot_id)
    msg response
    return response
  end

  # deletes a scale engine
  #   * argv = command-line arguments, require a scale engine id (-b) argument
  def cmd_delete_scale_engine argv
    setup argv
    bot_id = @hash['bot_id']
    response = @api.delete_scale_engine(bot_id)
    msg response
    return response
  end

private

  def setup argv
    parse_cli argv
    @host = (@@mu_ip.nil?) ? "127.0.0.1" : @@mu_ip
    @username  = (@@mu_admin_user.nil?) ? "admin" : @@mu_admin_user
    @password  = (@@mu_admin_pass.nil?) ? "admin" : @@mu_admin_pass
    @api = Scale.new(@host, @username, @password)
    response = @api.session
    msg response
    return response
  end

  def parse_cli argv
      @hash = {}
      args = Array.new
      while not argv.empty?
          args << argv.shift if argv.first[0,1] != '-'

          k = argv.shift

          if [ '-b', '--bot_id' ].member? k
            @hash['bot_id'] = shift(k, argv)
            next
          end

          if [ '-c', '--config_file' ].member? k
            puts "process -c"
            ENV['SCALE_CONFIG_FILE'] = shift(k, argv)
            next
          end

          if [ '-f', '--filename' ].member? k
            @hash['filename'] = shift(k, argv)
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

          if [ '-p', '--params' ].member? k
            @hash['params'] = shift(k, argv)
            next
          end

          if [ '-ps', '--view_position' ].member? k
            @hash['view_position'] = shift(k, argv)
            next
          end

          if [ '-pv', '--param_value' ].member? k
            @hash['param_value'] = shift(k, argv)
            next
          end

          if [ '-v', '--verbose' ].member? k
            $log.level = Logger::DEBUG
            next
          end

          if [ '-w', '--view' ].member? k
            @hash['view'] = shift(k, argv)
            next
          end

          if [ '-z', '--zoom' ].member? k
            @hash['zoom'] = shift(k, argv)
            next
          end
      end

      args
  end

  def help
        helps = [
            { :short => '-b', :long => '--bot_id', :value => '<string>', :help => 'scale engine identifier' },
            { :short => '-c', :long => '--config_file', :value => '<string>', :help => 'change json config_file' },
            { :short => '-f', :long => '--filename', :value => '<string>', :help => 'pcap filename' },
            { :short => '-h', :long => '--help', :value => '', :help => 'help on command line options' },
            { :short => '-m', :long => '--mu_string', :value => '<string>', :help => 'user, password, mu_ip in the form of admin:admin@10.9.8.7' },
            { :short => '-o', :long => '--output', :value => '<string>', :help => 'output logging to this file' },
            { :short => '-p', :long => '--params', :value => '<string>', :help => 'param(s) for configure or update' },
            { :short => '-ps', :long => '--view_position', :value => '<string>', :help => 'view position for data calls' },
            { :short => '-pv', :long => '--param_value', :value => '<string>', :help => 'param value for configure' },
            { :short => '-v', :long => '--verbose', :value => '', :help => 'set Logger::DEBUG level' },
            { :short => '-w', :long => '--view', :value => '<string>', :help => 'view (RUNTIME|CALLGRAPH) for data calls' },
            { :short => '-z', :long => '--zoom', :value => '<string>', :help => 'zoom value for data calls' }
        ]

       cmds = [
           "mu cmd_scale:about",
           "mu cmd_scale:configure -p <param> -pv <value>",
           "mu cmd_scale:data -w <view> -z <zoom> -ps <position> -b <bot_id>",
           "mu cmd_scale:delete_scale_engine -b <bot_id>",
           "mu cmd_scale:help",
           "mu cmd_scale:list",
           "mu cmd_scale:pattern  -z <zoom> -ps <position> ",
           "mu cmd_scale:pcap -b <bot_id> -f <filename>",
           "mu cmd_scale:release",
           "mu cmd_scale:release_scale_engine -b <bot_id>",
           "mu cmd_scale:reserve_scale_engine -b <bot_id>",
           "mu cmd_scale:session (a.k.a. /new)", # new
           "mu cmd_scale:start",
           "mu cmd_scale:status",
           "mu cmd_scale:statuses",
           "mu cmd_scale:stop",
           "mu cmd_scale:update -p <params>",
           "mu cmd_scale:verify"
        ]

        max_long_size = helps.inject(0) { |memo, obj| [ obj[:long].size, memo ].max }
        max_value_size = helps.inject(0) { |memo, obj| [ obj[:value].size, memo ].max }
        puts
        puts "Usage: mu cmd_scale <options>"
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
end
end
