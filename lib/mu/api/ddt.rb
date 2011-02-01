class Mu
class Ddt
  include Helper
  
  attr_accessor :host, :docroot, :username, :password, :session_id

  def initialize(host=ENV['MU_IP'], username=ENV['MU_ADMIN_USER'], password=ENV['MU_ADMIN_PASS'])
    @host = host
    @username  = username
    @password  = password
    @docroot = "/api/v5/ddt/"
    @session_id = nil
    @http = HttpHelper.new(@host, @username, @password, @docroot)
    msg "Created Ddt Api object to :#{@host}", Logger::DEBUG
  end

  # verifies the loaded scenario
  def run
    response = @http.post("session/test/run")
    msg response, Logger::DEBUG
    return response
  end

  # sets and executes test suite
  def run_testset(uuid)
    response = @http.post("session/test/runSuite/#{uuid}")
    msg response, Logger::DEBUG
    return response
  end

  # must be called first to establish a new Studio Verify session
  def new_session
    reply = @http.post("newSession") # with no args
    response = reply["response"]
    msg response, Logger::DEBUG
    @session_id = response["sessionId"]
    msg @session_id, Logger::DEBUG
    return @session_id  
  end

  # closes the existing Studio Verify session
  def close_session
    response = @http.get("session/closeSession")
    msg response, Logger::DEBUG
    return response
  end

  # returns array of session_ids
  def get_sessions
    all_sessions = Array.new
    response = @http.get("")  # with no args
    sessions = response["sessions"]
    if !sessions["session"].nil?
      num = sessions["session"].size
      if num > 1
        sessions["session"].each do | s |
          all_sessions << s["id"]
        end
      else # special case if there is only one (there is no array)
        all_sessions << sessions["session"]["id"]
      end
      return all_sessions
    end
    return nil
  end

  # closes all Studio Verify sessions
  def close_all_sessions
    response = @http.post("closeAllSessions")
    msg response, Logger::DEBUG
    return response
  end

  # returns the session id's of all existing Studio Verify sessions
  def get_all_sessions
    response = @http.get("getAllSessions")
    msg response, Logger::DEBUG
    return response
  end

  # sets up a test for run
  def setup_test
    response = @http.post("session/setupTest")
    msg response, Logger::DEBUG
    return response
  end

  # tears down a test
  def teardown_test
    response = @http.post("session/test/tearDownTest")
    msg response, Logger::DEBUG
    return response
  end

  # loads a scenario
  #   * the uuid of a scenario present on the Mu
  def load_scenario(uuid)
    response = @http.post("session/loadScenario/#{uuid}")
    msg response, Logger::DEBUG
    return response
  end

  # returns the hosts in the loaded scenario
  def get_hosts
    response = @http.get("session/scenario/hosts")
    msg response, Logger::DEBUG
    return response
  end

  # sets the hosts in the loaded scenario
  #   * roles = an array of the roles defined in the scenario
  #   * names = an array of host names to be mapped to the roles
  #   * type = network layer type (v4, v6 or l2) matching the defined roles
  def set_hosts(roles=[], names=[], type="v4")
    responses = Array.new
    hosts = roles.length.to_i
    hosts.times do | i |
       response = @http.post("session/scenario/hosts/#{roles[i]}/#{names[i]}/#{type}")
       responses << response
    end
    msg responses, Logger::DEBUG
    return responses
  end

  # returns the channel elements of the loaded scenario
  def get_channels
    response = @http.get("session/scenario/channels")
    msg response, Logger::DEBUG
    return response
  end

  # sets the channel elements of the loaded scenario
  #  * roles = an array of the roles defined for the channels in the scenario ('channel')
  #  * names = an array of host names to be mapped to the roles
  def set_channels(roles=[], names=[])
    responses = Array.new
    roles.length.times do | i |
        response = @http.post("session/scenario/channels/#{roles[i]}/#{names[i]}")
        responses << response
    end
    msg responses, Logger::DEBUG
    return responses
  end

  # returns the options from the loaded scenario
  def get_options
    response = @http.get("session/scenario/options")
    msg response, Logger::DEBUG
    return response
  end

  # sets the options for the loaded scenario
  #  * an array of option names
  #  * an array of option values
  def set_options(names=[], values=[])
    responses = Array.new
    names.length.times do | i |
       response = @http.post("session/scenario/options/#{names[i]}/#{values[i]}")
       responses << response
    end
    msg responses, Logger::DEBUG
    return responses
  end

  # collects results until the test is done or the timeout expires
  #   * time in seconds to wait for the test to complete
  def collect_results(timeout=120)
    wait_until_done(timeout)
    results = get_testset_results
    return results
  end

  # waits until the test is done or the timeout expires
  #   * timeout = the time in seconds to wait for the test to complete
  def wait_until_done(timeout=120)
    finished = false
    interval = timeout / 10
    10.times do
      begin
        response = get_testset_status
        #msg "wait_until_done, response = #{response}", Logger::DEBUG
        if !response.nil?
          if response.to_s.include?("Done")
            finished = true
            return finished
          end
        end
      rescue Exception => e
        puts e, Logger::DEBUG # status may not be ready right away. may return a 500
      end
      sleep interval
    end
    return finished
  end

  # returns the status of a running test set
  def get_testset_status
    response = @http.get("session/test/runSuite/status")
    msg response, Logger::DEBUG
    return response
  end

  # returns the results of a running test set. can be called repeatedly.
  # the test is done when the results include the 'END' keyword
  def get_testset_results
    response = @http.get("session/test/runSuite/results")
    msg response, Logger::DEBUG
    return response
  end

  # exports a testset to a csv file
  #   * uuid = the uuid of the testset to export
  def csv_export(uuid=@testset)
    response = @http.post("session/test/export/csv/#{uuid}")
    msg response, Logger::DEBUG
    return response
  end

private
 
  # imports a csv file to the Mu
  # (TODO: this method is not yet working)
  #  * filepath = the path to the csv file
  #  * filename = the name with which to save the file on the Mu
  def csv_import(filepath, filename)
    response = @http.post_form("session/test/import/csv", filepath, filename)
    msg response, Logger::DEBUG
    return response
  end
 
end
end

