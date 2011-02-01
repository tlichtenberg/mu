# The legacy Mu Api (for Fuzzing) is made available through this library and collection
# of executable methods.

require 'mu/api/muapi'
class Mu
class Command
class Cmd_muapi < Command

  attr_accessor :host, :username, :password, :api, :docroot

  # displays command-line help
  def cmd_help argv
    help
  end

  # for any of the possible status values, returns a list of analysis
  #   * command-line args require the status values to query, such as 'running' or 'failed'
  def cmd_list_by_status argv
    setup argv
    status = @hash['status']
    response = @api.list_by_status(status)
    if response.is_a?(Array)
      response.each do | r |
        msg r
      end
    else
      msg response
    end
  end

  # returns the status of a particular analysis
  #   * command-line args require the analysis' uuid
  def cmd_status argv
    setup argv
    uuid = @hash['uuid']
    response = @api.status(uuid)
    msg response
    return response
  end

  # runs an analysis, reference is the posted uuid
  # ex: run(1234-1234-1234-1234, "new_name")
  #   * command-line args require a uuid and an optional name such that each successive run of the same uuid yields a new name
  def cmd_run argv
    setup argv
    uuid = @hash['uuid']
    if @hash['boolean'].nil?
      rename = ""
    else
      rename = @hash['boolean']
    end
    response = @api.run(uuid, rename)
    msg response
    return response
  end

  # aborts a running analysis. the next queued analysis will start
  #   * command-line args require a uuid
  def cmd_stop argv
     setup argv
     uuid = @hash['uuid']
     response = @api.stop(uuid)
     msg response
     return response
  end

  # pauses a running analysis. Note that any queued analysis will NOT begin
  #   * command-line args require a uuid
  def cmd_pause argv
     setup argv
     uuid = @hash['uuid']
     response = @api.pause(uuid)
     msg response
     return response
  end

  # resumes a paused analysis
  #   * command-line args require a uuid
  def cmd_resume argv
    setup argv
    uuid = @hash['uuid']
    response = @api.resume(uuid)
    msg response
    return response
  end

  # delets an analysis or template of any type
  #   * command-line args require a uuid
  def cmd_delete argv
     setup argv
     uuid = @hash['uuid']
     response = @api.delete(uuid)
     msg response
     return response
  end

  # returns a list of faults (if any) for the analysis
  #   * command-line args require a uuid
  def cmd_get_faults argv
    setup argv
    uuid = @hash['uuid']
    response = @api.get_faults(uuid)
    if response.is_a?(Array)
      response.each do | r |
        msg r
      end
    else
      msg response
    end
    return response
  end

  # returns the name of a test referenced by uuid
  #   * command-line args require a uuid
  def cmd_get_name argv
     setup argv
     uuid = @hash['uuid']
     response = @api.get_name(uuid)
     msg response
     return response
  end

  # returns the types of templates on the Mu
  def cmd_types argv
     setup argv
     response = @api.types
     msg response
     return response
  end

  # lists all templates of the given type
  #   * command-line args require a type (such as 'scenario'_ and an option to return templates_only
  def cmd_list argv
    setup argv
    type = @hash['type']
    response = @api.list(type)
    if response.is_a?(Array)
      response.each do | r |
        msg r
      end
    else
      msg response
    end
    return response
  end

  # exports a template by type and name
  #   * command-line args requires a template type and template name
  def cmd_export_by_type_and_name argv
     setup argv
     type = @hash['type']
     name = @hash['name']
     response = @api.export_by_type_and_name(type, name)
     msg response
     return response
  end

  # exports a template by uuid
  #   * command-line args requires a template uuid
  def cmd_export_by_uuid argv
     setup argv
     uuid = @hash['uuid']
     response = @api.export_by_uuid(uuid)
     msg response
     return response
  end

  # archive has a set of three commands that are used to
  # generate and download an archive of all data produced by
  # a particular test
  # ex:
  #   * achive(run) returns job_id
  #   * archive(status) requires job_id
  #   * archive(get) if archive(status) == "Finished" requires job_id
  def cmd_archive argv
     setup argv
     command = @hash['command']
     job_id = @hash['uuid']
     response = @api.archive(command, job_id)
     msg response
     return response
  end

  # backup has a set of three commands that are used to generate,
  # query and retrieve a backup
  # ex:
  #   * backup(run) returns job_id
  #   * backup(status) requires job_id
  #   * backup(get) requires job_id
  #   * name = backup file name (will be given a .dat extension)
  def cmd_backup argv
     setup argv
     command = @hash['command']
     name = @hash['name']
     response = @api.backup(command, name)
     msg response
     return response
  end

  # capture has a set of three commands that are used to generate
  # packet captures, poll the status and return the resulting file
  # ex:
  #   * capture(run) returns job_id
  #   * capture(status) requires job_id
  #   * capture(get) requires job_id
  #   * port = the Mu interface on which to capture packets
  def cmd_capture argv
     setup argv
     command = @hash['command']
     port = @hash['port']
     job_id = @hash['uuid']
     response = @api.capture(command, port, job_id)
     msg response
     return response
  end

private

  def setup argv
    parse_cli argv
    @host = (@@mu_ip.nil?) ? "127.0.0.1" : @@mu_ip
    @username  = (@@mu_admin_user.nil?) ? "admin" : @@mu_admin_user
    @password  = (@@mu_admin_pass.nil?) ? "admin" : @@mu_admin_pass
    @docroot = "/api/v3"
    @params = nil
    @expected_error = nil
    @api = Muapi.new(@host, @username, @password)
    msg "Created API object to :#{@host}", Logger::DEBUG
  end

  def parse_cli argv   
      args = Array.new
      @hash = Hash.new
      while not argv.empty?
          args << argv.shift if argv.first[0,1] != '-'

          k = argv.shift

          if [ '-b', '--boolean' ].member? k
              @hash['boolean'] = shift(k, argv)
              next
          end

          if [ '-c', '--command' ].member? k
              @hash['command'] = shift(k, argv)
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

          if [ '-n', '--name' ].member? k
              @hash['name'] = shift(k, argv)
              next
          end

          if [ '-o', '--output' ].member? k
            $stdout.reopen(shift(k, argv), "w")
            next
          end

          if [ '-p', '--port' ].member? k
              @hash['port'] = shift(k, argv)
              next
          end

          if [ '-s', '--status' ].member? k
              @hash['status'] = shift(k, argv)
              next
          end

          if [ '-t', '--type' ].member? k
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
            { :short => '-b', :long => '--boolean', :value => '<string>', :help => 'boolean arg' },
            { :short => '-c', :long => '--command', :value => '<string>', :help => 'e.g. run|get|status' },
            { :short => '-h', :long => '--help', :value => '', :help => 'help on command line options' },
            { :short => '-m', :long => '--mu_string', :value => '<string>', :help => 'user, password, mu_ip in the form of admin:admin@10.9.8.7' },
            { :short => '-n', :long => '--name', :value => '<string>', :help => 'name for filtering' },
            { :short => '-o', :long => '--output', :value => '<string>', :help => 'output logging to this file' },
            { :short => '-p', :long => '--port', :value => '<string>', :help => 'port name' },
            { :short => '-s', :long => '--status', :value => '<string>', :help => 'status, running|finished|aborted|queued|failed' },
            { :short => '-t', :long => '--type', :value => '<string>', :help => 'template type' },
            { :short => '-u', :long => '--uuid', :value => '<string>', :help => 'template uuid' },
            { :short => '-v', :long => '--verbose', :value => '', :help => 'set Logger::DEBUG level' }
        ]

        cmds = [
           "mu cmd_muapi:archive -c <command> -u <uuid>",
           "mu cmd_muapi:backup -c <command> [-n <name>]",
           "mu cmd_muapi:capture -c <command> -p <port> [-u <uuid>]",
           "mu cmd_muapi:delete -u <uuid>",
           "mu cmd_muapi:export_by_type_and_name -t <type> -n <name>",
           "mu cmd_muapi:export_by_uuid -u <uuid>",
           "mu cmd_muapi:get_faults -u <uuid>",
           "mu cmd_muapi:get_name -u <uuid>",
           "mu cmd_muapi:help",
           "mu cmd_muapi:list -t <type>",
           "mu cmd_muapi:list_by_status -s <status>",
           "mu cmd_muapi:pause -u <uuid>",
           "mu cmd_muapi:resume -u <uuid>",
           "mu cmd_muapi:run -u <uuid> [-b rename]",
           "mu cmd_muapi:status -u <uuid>",
           "mu cmd_muapi:stop -u <uuid>",
           "mu cmd_muapi:types",
        ]

        max_long_size = helps.inject(0) { |memo, obj| [ obj[:long].size, memo ].max }
        max_value_size = helps.inject(0) { |memo, obj| [ obj[:value].size, memo ].max }
        puts
        puts "Usage: mu cmd_muapi <options>"
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
