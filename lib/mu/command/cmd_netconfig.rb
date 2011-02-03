# Use these commands to access the legacy REST API for configuring Mu interfaces, network hosts, and routes
require 'mu/api/netconfig'
class Mu
class Command
class Cmd_netconfig < Command

  attr_accessor :host, :username, :password, :api

  # displays command-line help
  def cmd_help argv
    help
  end

  # returns a json representation of the specified element
  #   * argv = command-line arguments, requires an element (-e) argument, such as 'interfaces', 'hosts' or 'routes' or 'interfaces/a1' or 'hosts/dell-9'
  def cmd_get argv
    setup argv
    e = @hash['element']
    response = @api.get(e)
    msg JSON.pretty_generate(response)
    return response
  end

  # modifies a network element
  #   * argv = command-line arguments, requires a json configuration (-j) and the element (-e) to modify, such as 'interfaces', 'hosts' or 'routes' or 'interfaces/a1' or 'hosts/dell-9'
  def cmd_modify argv
    setup argv
    json = @hash['json']
    e = @hash['element']
    response = @api.modify(json, e)
    msg response
    return response
  end


  # creates a new network element
  #   * argv = command-line arguments, requires a json configuration (-j) and the element (-e) to modify, such as 'interfaces', 'hosts' or 'routes'
  def cmd_create argv
    setup argv
    json = @hash['json']
    e = @hash['element']
    response = @api.create(json, e)
    msg response
    return response
  end

  # deletes an existing network element
  #   * argv = command-line arguments, requires a json configuration (-j) and the element (-e) to modify, such as 'interfaces', 'hosts' or 'routes' or 'interfaces/a1' or 'hosts/dell-9'
  def cmd_delete argv
    setup argv
    e = @hash['element']
    response = @api.delete(e)
    msg response
    return response
  end

  # restores the network configuration from a file
  #   * argv = command-line arguments, requires a path to a json configuration file (-f) , and a boolean (-b true|false) argument indicating whether or not existing elements should be cleared
  def cmd_restore argv
    setup argv
    filepath = @hash['filepath']
    clear_existing = to_boolean(@hash['boolean'])
    response = @api.restore(filepath, clear_existing)
    msg response
    return response
  end

  # clears existing network configuration hosts
  #   * argv = command-line arguments 
  def cmd_clear_hosts argv
    setup argv
    response = @api.clear_hosts
    msg JSON.pretty_generate(response)
    return response
  end

  # resolves network configuration hosts
  #   * argv = command-line arguments, requires the name (-n) of the host to resolve (determines its ip address and adds it to the network configuration)
  def cmd_resolve_hosts argv
    setup argv
    name = @hash['name']
    response = @api.resolve_hosts(name)
     msg response
    return response
  end

  # clears existing network interfaces
  #   * argv = command-line arguments, require the names of the interfaces to clear (-i name)
  def cmd_clear_interface argv
    setup argv
    interface = @hash['interfaces']
    response = @api.clear_interface(interface)
    msg response
    return response
  end

  # clears existing vlan configurations
  #  * argv = command-line arguments 
  def cmd_clear_vlans argv
    setup argv
    response = @api.clear_vlans
    msg response
    return response
  end

  # clears existing network routes
  #   * argv = command-line arguments 
  def cmd_clear_routes argv
    setup argv
    response = @api.clear_routes
    msg response
    return response
  end


  # saves the network configuration to a file
  #   * argv = command-line arguments, requires the element (-e element, such as 'interfaces', or -e all) to save, and a file name (-f) to save the settings to
  def cmd_save argv
    setup argv
    e = @hash['elements']
    filepath = @hash['filepath'] || "config.json"
    response = @api.save(e, filepath)
    msg response
    return response
  end

private

  def setup argv
    parse_cli argv
    @host = (@@mu_ip.nil?) ? "127.0.0.1" : @@mu_ip
    @username  = (@@mu_admin_user.nil?) ? "admin" : @@mu_admin_user
    @password  = (@@mu_admin_pass.nil?) ? "admin" : @@mu_admin_pass
    @response = nil
    @element = "" # sticky variable will hold a default element, the last element specified
    @api = Netconfig.new(@host, @username, @password)
    msg "Created Netconfig API object to :#{@host}", Logger::DEBUG
  end
  
  def parse_cli argv
      args = Array.new
      @hash = {}
      while not argv.empty?
          args << argv.shift if argv.first[0,1] != '-' 

          k = argv.shift

          if [ '-b', '--boolean' ].member? k
            @hash['boolean'] = shift(k, argv)
            next
          end

          if [ '-e', '--element' ].member? k
            @hash['element'] = shift(k, argv)
            next
          end

          if [ '-f', '--filepath' ].member? k
            @hash['filepath'] = shift(k, argv)
            next
          end

          if [ '-h', '--help' ].member? k
            help
            exit
          end

          if [ '-i', '--interfaces' ].member? k
            @hash['interfaces'] = shift(k, argv)
            next
          end

          if [ '-j', '--json' ].member? k
            @hash['json'] = shift(k, argv)
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

          if [ '-n', '--name' ].member? k
            @hash['name'] = shift(k, argv)
            next
          end

          if [ '-o', '--output' ].member? k
            $stdout.reopen(shift(k, argv), "w")
            next
          end

          if [ '-r', '--routes' ].member? k
            @hash['routes'] = shift(k, argv)
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
            { :short => '-b', :long => '--boolean', :value => '<string>', :help => 'boolean arg' },
            { :short => '-e', :long => '--element', :value => '<string>', :help => 'http string' },
            { :short => '-f', :long => '--filepath', :value => '<string>', :help => 'filepath' },
            { :short => '-h', :long => '--help', :value => '', :help => 'help on command line options' },
            { :short => '-i', :long => '--interfaces', :value => '<string>', :help => 'interfaces/hosts' },
            { :short => '-j', :long => '--json', :value => '<string>', :help => 'json object' },
            { :short => '-m', :long => '--mu_string', :value => '<string>', :help => 'user, password, mu_ip in the form of admin:admin@10.9.8.7' },
            { :short => '-n', :long => '--name', :value => '<string>', :help => 'host name' },
            { :short => '-o', :long => '--output', :value => '<string>', :help => 'output logging to this file' },
            { :short => '-v', :long => '--verbose', :value => '', :help => 'set Logger::DEBUG level' }
        ]

        cmds = [
           "mu cmd_netconfig:clear_hosts",
           "mu cmd_netconfig:clear_interfaces -i <interfaces>",
           "mu cmd_netconfig:clear_routes",
           "mu cmd_netconfig:clear_vlans",
           "mu cmd_netconfig:create -j <json> -e <element>",
           "mu cmd_netconfig:delete -e <element>",
           "mu cmd_netconfig:get -e <element>",
           "mu cmd_netconfig:help",
           "mu cmd_netconfig:modify -j <json> -e <element>",
           "mu cmd_netconfig:resolve_hosts -n <name>",
           "mu cmd_netconfig:restore -f <filepath> [-b <clear_existing>]",
           "mu cmd_netconfig:save -e <element> -f <filepath>",
        ]

        max_long_size = helps.inject(0) { |memo, obj| [ obj[:long].size, memo ].max }
        max_value_size = helps.inject(0) { |memo, obj| [ obj[:value].size, memo ].max }
        puts
        puts "Usage: mu cmd_netconfig <options>"
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


