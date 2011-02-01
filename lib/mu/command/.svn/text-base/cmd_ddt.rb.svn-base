# The Mu Ddt Api (For Studio Verify) is made available through this collection
# of Api methods to setup and run a functional test suite.
# (note: import_csv is not yet implemented, so the csv must currently be resident
# on the Mu and is referenced by its uuid)

require 'mu/api/ddt'
class Mu
class Command
class Cmd_ddt < Command

  attr_accessor :host, :username, :password, :api, :hash

  # displays command-line help
  def cmd_help argv
    help
  end

  # verifies the loaded scenario
  # * command-line args
  def cmd_run argv  
    setup argv
    response = @api.run
    msg response
    return response
  end

  # runs the loaded scenario and testset
  #   * command-line args
  def cmd_run_testset argv
    setup argv
    uuid = @hash['uuid']
    response = @api.run_testset(uuid)
    msg response
    return response
  end

  # creates a new Studio Verify session
  #   * command-line args
  def cmd_new_session argv
    setup argv
    response = @api.new_session
    msg response
    return response
  end

  # closes the currently active Studio Verify session
  #   * command-line args
  def cmd_close_session argv
    setup argv
    response = @api.close_session
    msg response
    return response
  end

  # returns an array of current Studio Verify session id's
  #   * command-line args
  def cmd_get_sessions argv
    setup argv
    response = @api.get_sessions
    msg response
    return response
  end

  # closes all existing Studio Verify sessions# * command-line args
  #   * command-line args
  def cmd_close_all_sessions argv
    setup argv
    response = @api.close_all_sessions
    msg response
    return response
  end

  # returns all Studio Verify sessions
  #   * command-line args
  def cmd_get_all_sessions argv
    setup argv
    response = @api.get_all_sessions
    msg response
    return response
  end

  # sets up a test session
  #   * command-line args
  def cmd_setup_test argv
    setup argv
    response = @api.setup_test
    msg response
    return response
  end

  # tears down a test session
  #   * command-line args
  def cmd_teardown_test argv
    setup argv
    response = @api.teardown_test
    msg response
    return response
  end

  # loads a Mu Studio scenario
  #   * command-line args require the uuid of a scenario that is already loaded on the Mu
  def cmd_load_scenario argv
    setup argv
    uuid = @hash['uuid']
    response = @api.load_scenario(uuid)
    msg response
    return response
  end

  # returns array of host hashmaps, e.g.
  # [{"role"=>"192.168.30.188 (A1.V4)", "roleId"=>"host_0", "layer"=>"v4"}, {"role"=>"192.168.30.9 (dell-eth1.V4)", "roleId"=>"host_1", "layer"=>"v4"}]
  # NOTE: the values of 'roleId' are what are passed to set_hosts as 'roles', not 'role'
  #   * command-line args
  def cmd_get_hosts argv
    setup argv
    response = @api.get_hosts
    msg response
    return response
  end
  
  # sets a Mu Studio scenario's host. takes an arrays of roles and names, e.g. ["h1", "h2"], ["a1", dell-9"]
  # optional types array ["v4", "v4"]
  #   * command-line args require an array of roles and names (and optionally, type). The roles must match those defined within the scenario
  def cmd_set_hosts argv
    setup argv
    roles = @hash['roles']
    names = @hash['names']
    if @hash['type'].nil?
      type = "v4"
    else
      type = @hash['type']
    end

    if names.include?(",")
      names_array = names.split(",")
    else
      names_array = Array.new
      names_array << names
    end

    if roles.include?(",")
      roles_array = roles.split(",")
    else
      roles_array = Array.new
      roles_array << roles
    end

    response = @api.set_hosts(roles_array, names_array, type)
    msg response
    return response
  end

  # returns the channel elements of a Mu Studio scenario
  #   * command-line args
  def cmd_get_channels argv
    setup argv
    response = @api.get_channels
    msg response
    return response
  end

  # sets the channel elements of a loaded scenario
  #   * command-line args requires arrays of roles and names. The roles must all be 'channel' and the names are names of valid hosts
  def cmd_set_channels argv
    setup argv
    roles = @hash['roles']
    names = @hash['names']

    if names.include?(",")
      names_array = names.split(",")
    else
      names_array = Array.new
      names_array << names
    end

    if roles.include?(",")
      roles_array = roles.split(",")
    else
      roles_array = Array.new
      roles_array << roles
    end

    response = @api.set_channels(roles_array, names_array)
    msg response
    return response
  end

  # returns array of options hashmap, consisting of name and value keys, e.g.
  # [{"name"=>"io.timeout", "value"=>250}, {"name"=>"io.delay", "value"=>0}]
  #   * command-line args
  def cmd_get_options argv
    setup argv
    response = @api.get_options
    msg response
    return response
  end

  # sets the options of the loaded scenario
  #  # * command-line args requires arrays of valid options names and values
  def cmd_set_options argv
    setup argv
    names = @hash['names']
    values = @hash['option_values']

    if names.include?(",")
      names_array = names.split(",")
    else
      names_array = Array.new
      names_array << names
    end

    if values.include?(",")
      values_array = values.split(",")
    else
      values_array = Array.new
      values_array << values
    end

    response = @api.set_options(names_array, values_array)
    msg response
    return response
  end

  # returns the status of the current testset
  #   * command-line args
  def cmd_get_testset_status argv
    setup argv
    response = @api.get_testset_status
    msg response
    return response
  end

  # returns results from the current testset. can be called repeatedly during a test run.
  # the end of a test is indicated by the presence of the word 'END' in the returned results array
  #   * command-line args
  def cmd_get_testset_results argv
    setup argv
    response = @api.get_testset_results
    msg response
    return response
  end

  # displays testset results
  #   * command-line args
  def cmd_display_results argv
   setup argv
   response = @api.results
   msg response
    return response
  end

  # exports a testset from Mu Studio to a csv file
  #   * command-line args require a testset uuid
  def cmd_cvs_export argv
    setup argv
    msg @api.new_session
    uuid = @hash['uuid']
    response = @api.csv_export(uuid)
    @api.close_session
    msg response
    return response
  end

private

   # imports a csv-formatted testset to a Mu system
   # # TODO: this method is not yet workind
   #   * command-line args requires the csv testset file and a filename
  def cmd_cvs_import argv
    setup argv
    msg @api.new_session
    testset_file = @hash['testset']
    filename = @hash['filename']
    msg " call import with #{testset_file} and #{filename}", Logger::DEBUG
    response = @api.csv_import(testset_file, filename)
    @api.close_session
    msg response
    return response
  end
  
  def setup argv
    parse_cli argv
    @host = (@@mu_ip.nil?) ? "127.0.0.1" : @@mu_ip
    @username  = (@@mu_admin_user.nil?) ? "admin" : @@mu_admin_user
    @password  = (@@mu_admin_pass.nil?) ? "admin" : @@mu_admin_pass
    @cookie = ''
    @testset = ''
    @session_id = nil
    @results = Array.new
    @api = Ddt.new(@host, @username, @password)
    msg "Created DdtApi object to :#{@host}", Logger::DEBUG
  end

  def parse_cli argv
      args = Array.new
      @hash = Hash.new
      while not argv.empty?
          args << argv.shift if argv.first[0,1] != '-'

          k = argv.shift

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

          if [ '-n', '--names' ].member? k
              @hash['names'] = shift(k, argv)
              next
          end

          if [ '-o', '--output' ].member? k
            $stdout.reopen(shift(k, argv), "w")
            next
          end

          if [ '-p', '--option_values' ].member? k
              @hash['option_values'] = shift(k, argv)
              next
          end

          if [ '-r', '--roles' ].member? k
              @hash['roles'] = shift(k, argv)
              next
          end

          if [ '-t', '--testset' ].member? k
              @hash['testset'] = shift(k, argv)
              next
          end

          if [ '-y', '--type' ].member? k
              @hash['type'] = shift(k, argv)
              next
          end

          if [ '-u', '--uuid' ].member? k
              @hash['uuid'] = shift(k, argv)
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
            { :short => '-f', :long => '--filename', :value => '<string>', :help => 'filename for import' },
            { :short => '-h', :long => '--help', :value => '', :help => 'help on command line options' },
            { :short => '-m', :long => '--mu_string', :value => '<string>', :help => 'user, password, mu_ip in the form of admin:admin@10.9.8.7' },
            { :short => '-n', :long => '--names', :value => '<string>', :help => 'comma-separated list of names used for set_hosts and set_channels' },
            { :short => '-o', :long => '--output', :value => '<string>', :help => 'output logging to this file' },
            { :short => '-p', :long => '--option_values', :value => '<string>', :help => 'coma-separated list of values array used for set_options' },
            { :short => '-r', :long => '--roles', :value => '<string>', :help => 'comma-separated list of roles used for set_hosts and set_channels' },
            { :short => '-t', :long => '--testset', :value => '<string>', :help => 'csv testset for import' },
            { :short => '-u', :long => '--uuid', :value => '<string>', :help => 'uuid arg used for load_scenario and run_testset' },
            { :short => '-v', :long => '--verbose', :value => '', :help => 'set Logger::DEBUG level' },
            { :short => '-y', :long => '--type', :value => '<string>', :help => 'network layer (v4, b6, l2) used for set_hosts and set_channels' },
        ]

       cmds = [
          "mu cmd_ddt:display_results",
          "mu cmd_ddt:new_session",
          "mu cmd_ddt:load_scenario -u <uuid>",
          "mu cmd_ddt:get_hosts",
          "mu cmd_ddt:set_hosts -r <roles> -n <names> -y <type>",
          "mu cmd_ddt:get_channels",
          "mu cmd_ddt:set_channels -r <roles> -n <names>",
          "mu cmd_ddt:get_options",
          "mu cmd_ddt:set_options -n <names> -p <option values>",
          "mu cmd_ddt:get_sessions",
          "mu cmd_ddt:setup_test",
          "mu cmd_ddt:run",
          "mu cmd_ddt:run_testset -u <uuid>",
          "mu cmd_ddt:get_testset_results",
          "mu cmd_ddt:get_testset_status",
          "mu cmd_ddt:teardown_test",
          "mu cmd_ddt:close_session",
          "mu cmd_ddt:close_all_sessions",
          "mu cmd_ddt:cvs_export -u <uuid> "
       ]

        max_long_size = helps.inject(0) { |memo, obj| [ obj[:long].size, memo ].max }
        max_value_size = helps.inject(0) { |memo, obj| [ obj[:value].size, memo ].max }
        puts
        puts "Usage: mu cmd_ddt:<command> <options>"
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

=begin
  first, create a session context. In it we can load a scenario, set its hosts,
  channels and options

  Next, create a test context. In it we can verify a scenario (run), run
  a test set, and collect test results

  If we need to make changes to the scenario, we need to teardown_test to return
  to the session context, make the changes (set_hosts. set_options, set_channels),
  and then call setup_test to create a new test context

  Finally, we teardown_test and close_session

    basic order of operations:
  @api = DdtApi.new

  @api.new_session   # new session context
  @api.load_scenario(scenario_uuid)
  @api.set_hosts (required unless scenario template has the hosts you want) (host_roles_array, host_names_array)
  @api.set_channels (optional)
  @api.set_options (optional, to add or change scenario options)
  @api.setup_test  # takes the configured scenario and builds test context
  @api.run # to verify
  @api.run_testset(testsuite_uuid) # loads and runs test suite
  @api.get_testset_status  # poll until done
  @api.get_testset_results
  @api.teardown_test  # to return to the session context, tears down the test context
  @api.close_session # tears down the session context
=end
