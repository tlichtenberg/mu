# Verifies a  Mu Studio scenario xml template
require 'mu/api/ddt'
class Mu
class Command
class Cmd_runscenario < Command

  attr_accessor :host, :username, :password, :ddt_api, :errors

  # displays command-line help
  def cmd_help argv
     help
  end

  # verifies a Mu Studio scenario
  #   * command-line args
  def cmd_run argv
    args = parse_cli argv
    setup

    if not args['scenario']
      msg "scenario required"
      return help
    else
      if args['scenario'].include?(".xml")
         scenario = args['scenario']
      else # TODO: eventually, msl files may be supported by this api
        msg "only .xml files are currently supported"
        return help
      end
    end

    if not args['dir']
      dir = "."
    else
      dir = args['dir']
    end

    if scenario.include?("/")
      filename = scenario
    else
      filename = dir + "/" + scenario
    end

    if not args['interfaces']
      @interfaces = Array.new
    else
      @interfaces = args['interfaces'].split(",")
    end

    @errors = Array.new
    hosts_array = Array.new
    roles_array = Array.new
        
    begin
   msg "new session"
      @ddt_api.new_session
      msg filename, Logger::DEBUG
      f = File.open(filename)
      doc = Nokogiri::XML(f)
      response = @http.post_xml("templates/import", doc)
      msg "response from post(#{filename}):\n#{response}", Logger::DEBUG
      scenario_name = doc.xpath("//scenario")[0].attribute('name')
      hosts = doc.xpath("//hosts/host")
      uuid = doc.xpath("//scenario")[0].attribute('uuid')
      roles = doc.xpath("//hosts/host/role")
      ids = doc.xpath("//hosts/host/id")
      channels = doc.xpath("//steps/channel")
      type = doc.xpath("//hosts/host/type")[0].text

      if !@interfaces.empty?
        if @interfaces.size != hosts.size
          msg "Error. The number of hosts/interfaces specified on the command-line does not equal the number
               of hosts in the template. #{@interfaces.size} != #{hosts.size}"
          return
        end
      end
      
      msg @ddt_api.load_scenario(uuid)

      roles.each_with_index do | r, i |
         content = r.text
         if @interfaces.empty?
           begin
             host = content.match(/\(.*\)/).to_s
             host = host[1, host.index(".") - 1].downcase
             hosts_array << host
           rescue => e
             msg e
             msg "expected to find host name embedded in role, e.g. 'client (A1.V4)'"
           end
         else
           hosts_array << @interfaces[i]
         end
         roles_array << content # use the whole name for the role
      end

      msg @ddt_api.set_hosts(roles_array, hosts_array, type)

      # if there are channels in the scenario, bind them
      if channels.size > 0
        channel_roles = Array.new
        channel_names = Array.new
        arg_channels = args['channel'].split(",")
        arg_channels.each do | c |
          channel_roles << "channel" # role is always "channel"
          channel_names << c
        end
        msg @ddt_api.set_channels(channel_roles, channel_names)
      end

      # verify the scenario
      msg @ddt_api.setup_test
      response = @ddt_api.run
      if response == ""
        msg "==> #{scenario_name} run returned without status"
        @errors << "#{scenario_name}: status = #{response}"
      else
        doc = Nokogiri::XML(response)
        status = doc.xpath("//status")[0].content
        msg "==> #{scenario_name}: status = #{status}"
        if status == 'failed'
        # on error, add to the errors array
          @errors << "#{scenario_name}: status = #{status}"
        end
      end

      @ddt_api.teardown_test
      @ddt_api.close_session

      # clear the hosts and roles array for the next iteration
      roles_array.clear
      hosts_array.clear
    end # if !exclude_list.include? and hosts.length
    # if there were errors, print them out and fail the test
    estr = ""
    if @errors.size > 0
      @errors.each do | e |
        estr = estr + e + "\n"
        msg estr
      end
   end
  ensure
    teardown
  end

private

  def setup
    @host = (@@mu_ip.nil?) ? "127.0.0.1" : @@mu_ip
    @username  = (@@mu_admin_user.nil?) ? "admin" : @@mu_admin_user
    @password  = (@@mu_admin_pass.nil?) ? "admin" : @@mu_admin_pass
    @ddt_api = Ddt.new(@host, @username, @password)
    @docroot ="/api/v3/"
    @http = HttpHelper.new(@host, @username, @password, @docroot)
  end

  def teardown
    unless @ddt_api.nil?
      @ddt_api.close_all_sessions
    end
  end

  def parse_cli argv
      hash = Hash.new
      while not argv.empty?
          break if argv.first[0,1] != '-'

          k = argv.shift

          if [ '-c', '--channel' ].member? k
              hash['channel'] = shift(k, argv)
              next
          end

          if [ '-d', '--dir' ].member? k
              hash['dir'] = shift(k, argv)
              next
          end

          if [ '-h', '--help' ].member? k
              help
              exit
          end

          if [ '-i', '--interfaces' ].member? k
              hash['interfaces'] = shift(k, argv)
              next
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

          if [ '-s', '--scenario' ].member? k
              hash['scenario'] = shift(k, argv)
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
            { :short => '-c', :long => '--channel', :value => '<string>', :help => 'channel name' },
            { :short => '-d', :long => '--dir', :value => '<string>', :help => 'directory containing the scenario file' },
            { :short => '-h', :long => '--help', :value => '', :help => 'help on command line options' },
            { :short => '-i', :long => '--interfaces', :value => '<string>', :help => 'comma-separated list of interfaces/hosts, e.g. b1,dell-server' },
            { :short => '-m', :long => '--mu_string', :value => '<string>', :help => 'user, password, mu_ip in the form of admin:admin@10.9.8.7' },
            { :short => '-o', :long => '--output', :value => '<string>', :help => 'output logging to this file' },
            { :short => '-s', :long => '--scenario', :value => '<string>', :help => 'scenario file to run' },
            { :short => '-v', :long => '--verbose', :value => '', :help => 'set Logger::DEBUG level' }
        ]

        cmds = [
           "mu cmd_runscenario:help",
           "mu cmd_runscenario:run -s <scenario> -i <hosts>"
        ]

        max_long_size = helps.inject(0) { |memo, obj| [ obj[:long].size, memo ].max }
        max_value_size = helps.inject(0) { |memo, obj| [ obj[:value].size, memo ].max }
        puts
        puts "Usage: mu cmd_runscenario:<command> <options>"
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