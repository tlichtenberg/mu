# runs Mu Studio multi-host app_id msl files in Studio Scale, in client/server passthrough
# mode, collapsing all hosts in the scenario to two. Runs either a single msl file or
# a directory of msl files, and has command-line options to specify the Mu parameters,
# the interfaces to use, and the pattern in which to run
require 'mu/api/scale'
class Mu
class Command
class Cmd_appid < Command

  attr_accessor :api, :params, :hosts, :addr_indexes, :hash

  # displays command-line help
  def cmd_help argv
     help
  end

  # returns a boolean indicating whether the scale test is running or not
  #  * argv = command-line arguments
  def cmd_running? argv
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

  # runs a single Studio Scale test
  #  * argv = command-line arguments, requires a scenario (-s) argument
  def cmd_run_file argv
    setup argv

    if not @hash['scenario']
      raise "*** Error: scenario required, using -s option"
    else
      scenario = @hash['scenario']
    end

    if !File.exists?(scenario)
      raise "*** Error: Scenario file #{scenario} was not found"
    end

    File.delete("app_id_status.json") if File.exists?("app_id_status.json")
    File.delete("app_id_stats.csv") if File.exists?("app_id_stats.csv")

    @api = Scale.new(@@mu_ip, @@mu_admin_user, @@mu_admin_pass)
    @api.configure("pattern", @cmd_line_pattern)
    @params = {}
    @params["msl"] = scenario
    @params["hosts"] = @cmd_line_hosts
    run(scenario)
    @api.release
  end

   # runs through a directory of msl files and executes a Studio Scale test for each one
   #  * argv = command-line arguments, require a directory (-d) argument
  def cmd_run_dir argv
    setup argv

    if not @hash['dir']
      raise "*** Error: directory required, using -d option"
    else
      dir = @hash['dir']
    end

    File.delete("app_id_status.json") if File.exists?("app_id_status.json")
    File.delete("app_id_stats.csv") if File.exists?("app_id_stats.csv")

    @api = Scale.new(@@mu_ip, @@mu_admin_user, @@mu_admin_pass)
    @api.configure("pattern", @cmd_line_pattern)
    @params = {}
    @params["dir"] = dir
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
       msg "no msl files found in #{dir}"
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

    if not @hash['testset']
      @testset = ""
    else
      @testset = @hash['testset']
    end

  end

  def run(msl)
   if !File.exists?(msl)
     return "file not found: #{msl}"
   end

   @api.configure("musl", File.read(msl))

   unless @testset.empty?
      if @testset.include?("/") # assume it is the full path in this case
        csv_file = @testset
      else
        csv_file = @params["dir"] + "/" + @testset
      end
      @api.configure("csv", File.read(csv_file))
    end

    set_global_hosts
    all_hosts = get_all_hosts_from_musl(msl)
    @hosts_config = map_all_hosts_to_json(all_hosts)
    @api.configure("hosts", @hosts_config)
    msg "verifying #{msl} ..."
    response = @api.verify
    # sleep 3
    v = parse_verify_response(response)
    if v.nil?
      msg "error in verify"
      return
    end
    if @verify_only
      msg v
      return
    end
    msg "starting #{msl} ..."
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
            dump_status(status, msl)
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
    msg "stopping #{msl} ..."
  end

  def set_global_hosts
    @hosts = Array.new
    @addr_indexes = Array.new
    hosts = @params["hosts"]
    if !hosts.nil?
      p = hosts.split(",")
      p.each do | h |
        if h.include?("-")  # b1-1000,b2-1 to indicate addr_count
          q = h.split("-")
          @hosts << q[0]
          @addr_indexes << q[1]
        else # default to the 1st addr index
          @hosts << h
          @addr_indexes << 1
        end
      end
    else
      @hosts = ['b1','b2']
      @addr_indexes = [1,1]
    end
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

  # finds all the hosts in the musl file
  def get_all_hosts_from_musl(msl)
    f = IO.read(msl)
    hosts = f.scan(/host_\d+/)
    hosts.uniq!
    return hosts
  end

  # maps host_0 to the client interface
  # maps all other hosts to the server interface
  def map_all_hosts_to_json(hosts=[])
    new_hosts = Array.new
    hosts.each_with_index do | h, i |
      if i == 0
        new_hosts << @hosts[0] + "/*,#{@addr_indexes[0]}" 
      else
        new_hosts << @hosts[1] + "/*,#{@addr_indexes[1]}" 
      end
    end

    hosts_config = {}

    # assign hosts to consecutive string keys, host_0, host_1, etc ...
    new_hosts.each_with_index do | h, i |
      hosts_config["host_#{i}"] = h # new_hosts[i]
    end

    # convert keys to symbols
    new_hosts_config = {}
    hosts_config.each_key { |k| new_hosts_config[k.to_sym] = hosts_config[k] }

    return new_hosts_config
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
    rescue
      # could nbe json parse error
      return nil
    end
  end

  def parse_status(status)  
    return nil if status.nil?
    msg JSON.pretty_generate(status), Logger::DEBUG
    @reported_volume = 0
    if !status["status"]["error"].nil?
      if status["status"]["error"] == true
        @error = status["status"]["error"]
        @reason = status["status"]["reason"]
        # puts "*** Error = #{@error}, reason = #{@reason} ***\n\n"
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

          if [ '-o', '--output'].member? k
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

      hash
  end

  def help
        helps = [
            { :short => '-c', :long => '--csv', :value => '<string>', :help => 'name of the csv testset to run' },
            { :short => '-d', :long => '--dir', :value => '<string>', :help => 'directory containing msl files, required for run_dir' },          
            { :short => '-h', :long => '--help', :value => '', :help => 'help on command line options' },
            { :short => '-i', :long => '--interfaces', :value => '<string>', :help => 'comma-separated list of interfaces, e.g. b1,b2 or b1-1000:0,b2 for ip range and offset' },
            { :short => '-m', :long => '--mu_string', :value => '<string>', :help => 'user, password, mu_ip in the form of admin:admin@10.9.8.7' },
            { :short => '-o', :long => '--output', :value => '<string>', :help => 'output logging to this file' },
            { :short => '-p', :long => '--pattern', :value => '<string>', :help => 'pattern in the form of comma-separated concurrency_start-end:duration strings, e.g. 1-10000:60,10000-1:30. Duration is in seconds' },
            { :short => '-s', :long => '--scenario', :value => '<string>', :help => 'msl file, required for run_msl' },
            { :short => '-t', :long => '--test', :value => '', :help => 'do verify only' },
            { :short => '-v', :long => '--verbose', :value => '', :help => 'set Logger::DEBUG level' }
        ]

        cmds = [
           "mu cmd_appid:help",
           "mu cmd_appid:run_file -s <file>",
           "mu cmd_appid:run_dir -d <dir>",
           "mu cmd_appid:running?"
        ]

        max_long_size = helps.inject(0) { |memo, obj| [ obj[:long].size, memo ].max }
        max_value_size = helps.inject(0) { |memo, obj| [ obj[:value].size, memo ].max }
        puts
        puts "Usage: mu cmd_appid:<command> <options>"
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
        puts "Outputs"
        puts
        puts "app_id_stats.csv"
        puts "scenario_name , passed , errors , timeouts,"
        puts "client tx bytes/sec , client tx msgs/sec , client rx bytes/sec , client rx msgs/src,"
        puts "server tx bytes/sec , server tx msgs/sec , server rx bytes/sec , server rx msgs/src"
        puts
        puts "app_id_status.json"
        puts "contains the last status json object returned from polling, per scenario"
    end

end
end # Command
end # Mu

