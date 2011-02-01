# Runs Mu Studio scenario msl files in Studio Scale, requiring that all interfaces and
# hosts used in the scenario are specified on the command-line through the –i option.
# Runs either a single msl file or a directory of msl files, and has command-line options
# to specify the Mu parameters, the interfaces to use, and the pattern in which to run
require 'mu/api/scale'
class Mu
class Command
class Cmd_runscale < Command

  attr_accessor :api, :params, :hosts, :addr_indexes, :offset_indexes

  # displays command-line help
  def cmd_help argv
     help
  end

  # sets up, executes, and closes a Studio Scale test
  #   * command-line args
  def cmd_run_file argv
    setup argv

    if not @hash['scenario']
      msg "scenario required"
      return help
    else
      if @hash['scenario'].include?(".msl")
         scenario = @hash['scenario']
      else # TODO: eventually, xml and mus file may be supported by scale api
        msg "only .msl files are currently supported"
        return help
      end
    end

    if not @hash['dir']
      @dir = ""
      path = scenario
    else
      @dir = @hash['dir']
      path = @dir + "/" + scenario
    end

    if !File.exists?(path)
      raise "*** Error: File #{path} does not exist"
    end

    @api = Scale.new(@@mu_ip, @@mu_admin_user, @@mu_admin_pass)
    @api.configure("pattern", @cmd_line_pattern)
    @params = {}
    @params["dir"] = @dir
    @params["msl"] = scenario
    @params["hosts"] = @cmd_line_hosts
    run(scenario)
    @api.release
  end

   # public method to be called to run through a directory of msl files
  def cmd_run_dir argv
    setup argv

    if not @hash['dir']
      return help
    else
      @dir = @hash['dir']
    end

    File.delete("app_id_status.json") if File.exists?("app_id_status.json")
    File.delete("app_id_stats.csv") if File.exists?("app_id_stats.csv")

    @api = Scale.new(@@mu_ip, @@mu_admin_user, @@mu_admin_pass)
    @api.configure("pattern", @cmd_line_pattern)
    @params = {}
    @params["dir"] = @dir
    @params["hosts"] = @cmd_line_hosts
    Dir.chdir(@params["dir"])
    File.delete("app_id_status.json") if File.exists?("app_id_status.json")
    files = Dir.glob("*.msl")
    if !files.empty?
       files.sort.each do | f |
         run(f)
         output_csv(f)
         sleep 2
       end
     else
       msg "no msl files found in #{@dir}"
     end
     @api.release
 end

private

 def setup argv
    parse_cli argv
    @params = {}

    if @hash['test']
      @verify_only = true
    else
      @verify_only = false
    end

    if not @hash['testset']
      @testset = ""
    else
      @testset = @hash['testset']
    end

    if not @hash['pattern']
      @cmd_line_pattern = "{ \"iterations\": 1, \"intervals\": [ {\"iterations\":1, \"end\":100, \"start\":1, \"duration\":20 } ] }"
    else
      @cmd_line_pattern = @hash['pattern']
    end

    if not @hash['interfaces']
      @cmd_line_hosts = "b1,b2"
    else
      @cmd_line_hosts = @hash['interfaces']
    end

  end

 def run(scenario)
    # assume the scenario and testset files are in dir unless they contain '/'
    # in which case they are assumed to be absolute paths
    if scenario.include?("/")
      musl_file = scenario
    else
      musl_file = @params["dir"] + "/" + scenario
    end
    # msg musl_file, Logger::DEBUG
    @api.configure("musl", File.read(musl_file))

    unless @testset.empty?
      if @testset.include?("/")
        csv_file = @testset
      else
        csv_file = @params["dir"] + "/" + @testset
      end
      @api.configure("csv", File.read(csv_file))
    end

    File.delete("app_id_status.json") if File.exists?("app_id_status.json")
    File.delete("app_id_stats.csv") if File.exists?("app_id_stats.csv")

    configure_hosts

    msg "verifying #{scenario} ..."
    response = @api.verify
    msg response, Logger::DEBUG
    # sleep 3
    v = parse_verify_response(response)
    msg "#{v}", Logger::DEBUG
    if v.nil?
      msg "error in verify"
      return
    end
    if @verify_only
      msg v
      return
    end
    msg "starting #{scenario} ..."
    @api.start
    start_time = Time.now.to_i
    while true
      sleep 5
      status = @api.status
      if !status.nil?
        if !status["status"].nil?
          if status["status"]["running"] == false
            msg "running = #{status["status"]["running"]}", Logger::DEBUG
            r = parse_status(status)
            dump_status(status, musl_file)
            return
          else
            r = parse_status(status)
          end
        else # status['status'].nil? ... no bonafide status was returned
          time_now = Time.now.to_i
          if time_now - start_time > 20
             # puts "\nError: timing out after 20 seconds. Test had failed to start or verify"
             break
          end
        end
      end
    end
  ensure
    msg "stopping #{scenario} ..."
  end

  def cmd_running?
    if @api.nil?
      msg "false"
      return
    end
    
    status = @api.status
    if !status.nil?
      if !status["status"].nil?
        msg status["status"]["running"]
      end
    else
      msg "false"
    end
  end           

  def configure_hosts
    @hosts = Array.new
    @addr_indexes = Array.new
    @offset_indexes = Array.new
    hosts = @params["hosts"]
    if !hosts.nil?
      p = hosts.split(",")
      p.each do | h |
        if h.include?("-")  # b1-1000,b2-1 to indicate addr_count
          q = h.split("-")
          @hosts << q[0]
          if q[1].include?(":") # -1000:20 to indicate offset within range
            r = q[1].split(":")
            @addr_indexes << r[0]
            @offset_indexes << r[1]
          else
            @addr_indexes << q[1]
            @offset_indexes << 1
          end
        else # default to the 1st addr index
          @hosts << h
          @addr_indexes << 1
          @offset_indexes << 1
        end
      end
    else
      @hosts = ['b1','b2']
      @addr_indexes = [1,1]
      @offset_indexes = [1,1]
    end

    set_hosts_byname(@hosts, @addr_indexes, @offset_indexes)
  end

  def set_hosts_byname(hosts=@hosts, count=[1,1], offset=[1,1], v4=true)
    new_hosts = Array.new
    str = ""
    hosts.each_with_index do |n, i|
      if n.match(/^[ab][1-4]$/) or n.include?(".")  # possible vlan
        if count[i] == 1 or count[i].nil?
           str = "#{n}/*"
        else
           str = "#{n}/*,#{count[i]},#{offset[i]}"
        end
        msg "using host #{str}", Logger::DEBUG
      else
        @net = Netconfig.new
        @net.setup(@hosts, @username, @password)
        if v4
          addr = @net.get("hosts/#{n}")['v4_addr']
        else
          addr = @net.get("hosts/#{n}")['v6_addr']
        end
        str = "#{addr}"
        msg "using host #{str}", Logger::DEBUG
      end
      new_hosts << str
    end
    set_hosts(new_hosts)
  end

  # expects full strings: e.g. b1/12.89.0.1 ...
  def set_hosts(hosts=["b1","b2"])
    host_params = {}

    # assign hosts to consecutive string keys, host_0, host_1, etc ...
    hosts.each_with_index do | h, i |
      host_params["host_#{i}"] = hosts[i]
    end
 
    # convert keys to symbols
    # host_params.each_key { |k| host_params[k.to_sym] = host_params[k] }
    new_host_params = {}
    host_params.each_key { |k| new_host_params[k.to_sym] = host_params[k] }

=begin
    # add default host, set to host_1 if it exists, unless specified on the command-line
    if @hash['default_host'].nil?
      new_host_params[:default_host] = new_host_params[:host_1] unless new_host_params[:host_1].nil?
    else
      new_host_params[:default_host] = @hash['default_host'] if !@hash['default_host'].nil?
    end
=end
    
    @api.configure("hosts", new_host_params)

  end

  def dump_status(status, msl)
    filename = "app_id_status.json"
    f = File.open(filename, "a")
    status["filename"] = msl
    str = JSON.pretty_generate(status)
    f.write(",") if !File.zero?(f) # if appending, we need to insert a comma
    f.write(str)
    f.close
  end

  def output_csv(msl_file)
    filename = "app_id_stats.csv"
    f = File.open(filename, "a")
    doc = "#{msl_file},#{@executed},#{@errors.to_i},#{@timeouts.to_i},#{@client_tx_bytes},#{@client_tx_msgs},#{@client_rx_bytes},#{@client_rx_msgs},#{@server_tx_bytes},#{@server_tx_msgs},#{@server_rx_bytes},#{@server_rx_msgs}\n"
    File.open(filename, 'a') {|f| f.write(doc) }
  end

  def parse_verify_response(response)
    if response.nil? # || response.empty?
      msg "*** error = no response received from /verify ***\n\n"
      return nil
    end
    begin
      msg JSON.pretty_generate(response), Logger::DEBUG
      if !response["status"].nil?
        if response["status"]["error"] == true
          @error = response["status"]["error"]
          @reason = response["status"]["reason"]
          dump_status(response)
          msg "*** Error = #{@error}, reason = #{@reason} ***\n\n"
          return nil
        end
      end
      msg "*** verify: okay ***", Logger::DEBUG
      return "*** verify: okay ***"
     rescue => e
      msg e, Logger::DEBUG
      return nil
    end
  end

  def parse_status(status)
    return nil if status.nil?
    @reported_volume = 0
    if !status["status"]["error"].nil?
      if status["status"]["error"] == true
        @error = status["status"]["error"]
        @reason = status["status"]["reason"]
        msg "*** Error = #{@error}, reason = #{@reason} ***\n\n"
        return nil
      end
    end

    @stats_summary = status["status"]["statistics"]["summary"]
    @duration = @stats_summary["duration"]
    @instances = @stats_summary["instances"]
    @total_instances = @instances["total"]
    @executed = @instances["executed"]
    @timeouts = @instances["timeouts"]
    @errors = @instances["errors"]
    @asserts_failed = @stats_summary["asserts"]["failed"]
    @server = @stats_summary["server"]
    @server_tx_bytes = @server["tx"]["bytes"]
    @server_tx_msgs = @server["tx"]["msgs"]
    @server_rx_bytes = @server["rx"]["bytes"]
    @server_rx_msgs = @server["rx"]["msgs"]
    @client = @stats_summary["client"]
    @client_tx_bytes = @client["tx"]["bytes"]
    @client_tx_msgs = @client["tx"]["msgs"]
    @client_rx_bytes = @client["rx"]["bytes"]
    @client_rx_msgs = @client["rx"]["msgs"]
    @scenarios = status["status"]["statistics"]["scenarios"]
    @scenarios.each do | scenario |
      @reported_volume = @reported_volume + scenario["volume"]
    end

    msg ""
    msg "duration:           #{format_float(2, @duration)}"
    msg "concurrency:        #{@reported_volume}"
    msg "tests/sec:          #{format_float(2, @executed.to_f / @duration)}" if @duration.to_i > 0
    msg "passed:             #{@executed}"
    msg "errors:             #{@errors}"
    msg "timeouts:           #{@timeouts}"
    msg "client tx bytes/sec #{format_float(2, @client_tx_bytes.to_f / @duration)}" if @duration.to_i > 0
    msg "client tx msgs/sec  #{format_float(2, @client_tx_msgs.to_f / @duration)}" if @duration.to_i > 0
    msg "client rx bytes/sec #{format_float(2, @client_rx_bytes.to_f / @duration)}" if @duration.to_i > 0
    msg "client rx msgs/sec  #{format_float(2, @client_rx_msgs.to_f / @duration)}" if @duration.to_i > 0
    msg "server tx bytes/sec #{format_float(2, @server_tx_bytes.to_f / @duration)}" if @duration.to_i > 0
    msg "server tx msgs/sec  #{format_float(2, @server_tx_msgs.to_f / @duration)}" if @duration.to_i > 0
    msg "server rx bytes/sec #{format_float(2, @server_rx_bytes.to_f / @duration)}" if @duration.to_i > 0
    msg "server rx msgs/sec  #{format_float(2, @server_rx_msgs.to_f / @duration)}" if @duration.to_i > 0
    msg ""
  end

  def parse_cli argv
      @hash = Hash.new
      while not argv.empty?
          break if argv.first[0,1] != '-'

          k = argv.shift

          if [ '-c', '--csv' ].member? k
              @hash['testset'] = shift(k, argv)
              next
          end

          if [ '-d', '--dir' ].member? k
              @hash['dir'] = shift(k, argv)
              next
          end

          if [ '-f', '--default_host' ].member? k
              @hash['default_host'] = shift(k, argv)
              next
          end

          if [ '-i', '--interfaces' ].member? k
              @hash['interfaces'] = shift(k, argv)
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

          if [ '-p', '--pattern' ].member? k
            patterns = Array.new
            pattern_string = shift(k, argv)
            pstrings = pattern_string.split(",")
            pstrings.each do | p |
              if p =~ /(.+?)-(.+?):(.*)/ # e.g. 1-10000:60
                start_vol = $1
                end_vol = $2
                duration = $3
                patterns << "{\"iterations\":1, \"end\":#{end_vol}, \"start\":#{start_vol}, \"duration\":#{duration} }"
              end
            end
            ps = "{ \"iterations\": 1, \"intervals\": ["
            patterns.each do | p |
              ps = ps + p + ","
            end
            ps = ps[0..ps.length-2] # remove final comma
            ps = ps + "] }"
            @hash['pattern'] = ps
            next
          end

          if [ '-s', '--scenario' ].member? k
              @hash['scenario'] = shift(k, argv)
              next
          end

          if [ '-t', '--test' ].member? k
              @hash['test'] = true
              next
          end
          
          if [ '-v', '--verbose' ].member? k
            $log.level = Logger::DEBUG
            next
          end

          raise ArgumentError, "Unknown option #{k}"
      end

      @hash
  end

  def help
        helps = [
            { :short => '-c', :long => '--csv', :value => '<string>', :help => 'name of the csv testset to run' },
            { :short => '-d', :long => '--dir', :value => '<string>', :help => 'directory containing the scenario file' },
            { :short => '-f', :long => '--default_host', :value => '<string>', :help => 'default_host setting' },
            { :short => '-h', :long => '--help', :value => '', :help => 'help on command line options' },
            { :short => '-i', :long => '--interfaces', :value => '<string>', :help => 'comma-separated list of interfaces, e.g. b1,b2 or b1-1000,b2 for ip range' },
            { :short => '-m', :long => '--mu_string', :value => '<string>', :help => 'user, password, mu_ip in the form of admin:admin@10.9.8.7' },
            { :short => '-o', :long => '--output', :value => '<string>', :help => 'output logging to this file' },
            { :short => '-p', :long => '--pattern', :value => '<string>', :help => 'pattern in the form of comma-separated concurrency_start-end:duration patterns, e.g. 1-100:60,100-100:60,100-1:60' },
            { :short => '-s', :long => '--scenario', :value => '<string>', :help => 'scenario file to run' },
            { :short => '-t', :long => '--test', :value => '', :help => 'do verify only' },
            { :short => '-v', :long => '--verbose', :value => '', :help => 'set Logger::DEBUG level' }
        ]

        cmds = [
           "mu cmd_runscale:help",
           "mu cmd_runscale:run_file -s <scenario>  -i <hosts, e.g. a1,dell-9> -p <pattern, e.g. 1-1000:30>",
           "mu cmd_runscale:run_dir -d <scenario_directory>",
           "mu cmd_runscale:running?"
        ]

        max_long_size = helps.inject(0) { |memo, obj| [ obj[:long].size, memo ].max }
        max_value_size = helps.inject(0) { |memo, obj| [ obj[:value].size, memo ].max }
        puts
        puts "Usage: mu cmd_runscale:<command> <options>"
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

