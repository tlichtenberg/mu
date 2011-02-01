class Mu
class Scale
  include Helper

  attr_accessor :host, :username, :password, :docroot, :configuration, :config_file, :uuid

  def initialize(host=ENV['MU_IP'], username=ENV['MU_ADMIN_USER'], password=ENV['MU_ADMIN_PASS'])
    @host = host
    @username  = username
    @password  = password
    @docroot = "/api/v5/scale/"
    @uuid = nil
    @http = HttpHelper.new(@host, @username, @password, @docroot)
    @config_file = (ENV['SCALE_CONFIG_FILE'].nil?) ? "scale.json" : ENV['SCALE_CONFIG_FILE']
    if File.readable? @config_file
      msg "reading config file: #{@config_file}", Logger::DEBUG
      @configuration = JSON.parse File.read(@config_file)
    else
      @configuration = {
        "hosts"=> {
          "host_0"=> "a1/*",
          "host_1"=> "a2/*"
        },
        "timeout"=> 5000,
        "delay"=> 0,
        "volume"=> 1,
        "holdConcurrency"=> true,
        "limitConcurrency"=> false,
        "vectorAddressPairing"=> false,
        "musl" => "",
        "csv" => "",
        "pattern" => {}
      }
    end
    @uuid = session
    msg "Created Scale Api session [#{@uuid}] on :#{@host}", Logger::DEBUG
  end

  # creates a new Studio Scale session, returning the session id
  def session
     uuid = nil
     list = get("list")
     if !list.empty?
         msg list
         uuid = list[0]  # return existing session identifier if there is one
         return uuid
     end
     uuid = get "new" # return a new session identifier
     msg "uuid from /new = #{uuid}"
     return uuid
  end

  # configures a parameter in the class @configuration object
  #   * param = the parameter to configure (e.g. volume)
  #   * value = the parameter's value ( e.g. 100)
  def configure(param, value)
     if param == "pattern" and value.is_a?(String)
         value = JSON.parse(value)
     end
     @configuration[param] = value
     File.open("scale_configuration.json",'w'){|f| f.write(JSON.pretty_generate(@configuration))}
  end

  # starts a scale test with the class @configuration object
  def start
      response = post "start", {"request" => @configuration}
      msg response, Logger::DEBUG
      return response
  end

  # verifies the class @configuration object
  def verify
      response = post "verify", {"request" => @configuration}
      msg response, Logger::DEBUG
      return response
  end

  # updates a running scale test, as long as the test pattern is 'none'
  #   * params = a json object containing the information to update, such as { "volume" : 100 }
  def update(params)
      response = get "update", params
      msg response, Logger::DEBUG
      return response
  end

  # gets information about the currently running Scale test.
  def status
      response = get "status"
      msg response, Logger::DEBUG
      return response
  end

  # returns the current Scale Player's session id
  def list
      response = get "list"
      msg response, Logger::DEBUG
      return response
  end

  # lists information about the the Scale Player and all active and inactive Scale Engines
  def about
      response = get "about"
      msg response, Logger::DEBUG
      return response
  end

  # returns a packet capture file from scale verify
  #   * the id of the scale engine
  #   * the name of the pcap file to retrieve
  def pcap(botId, file)
      response = get "pcap", "botId=#{botId}&file=#{file}"
      msg response, Logger::DEBUG
      return response
  end

  # gets the status of all active and inactive Scale engines
  def statuses
      response = get "statuses"
      msg response, Logger::DEBUG
      return response
  end

  # gets chart data for the Scale test
  #   * view = the TIMELINE or CALLGRAPH chart.
  #   * zoom = the zoom level (0 to 1). 1 returns data for 100% of the time range, 0.5 returns data for 50% of the time range, and 0 returns only the last minute of data
  #   * position = 0.
  #   * bot_id = the scale engine id
  def data(view='TIMELINE', zoom="0", position="0", bot_id="")
      response = get "data", "view=#{view.upcase}&zoom=#{zoom}&position=#{position}&bot_id=#{bot_id}"
      msg response, Logger::DEBUG
      return response
  end

  # returns scale test data for charting
  #  * command-line args require a zoom level and position(0)
  #   * zoom = the zoom level (0 to 1). 1 returns data for 100% of the time range, 0.5 returns data for 50% of the time range, and 0 returns only the last minute of data
  #   * position = 0.
  def pattern(zoom="0", position="0")
      response = get "pattern", "zoom=#{zoom}&position=#{position}"
      msg response, Logger::DEBUG
      return response
  end

  # stops a scale test
  def stop
      response = get "stop"
      msg response, Logger::DEBUG
      return response
  end

  # releases the scale player
  def release
      response = get "release"
      msg response, Logger::DEBUG
      return response
  end

  # marks the specified Scale Engine as active (will participate in a Scale test
  #  * bot_id = the scale engine id
  def reserve_scale_engine(bot_id)
      response = get "reserveScaleEngine", "botId=#{bot_id}"
      msg response, Logger::DEBUG
      return response
  end

  # marks the specified Scale Engine as inactive (will not participate in a Scale test)
  #  * bot_id = the scale engine id
  def release_scale_engine(bot_id)
      response = get "releaseScaleEngine", "botId=#{bot_id}"
      msg response, Logger::DEBUG
      return response
  end

  # removes a Scale engine from the list of available engines
  #  * bot_id = the scale engine id
  def delete_scale_engine(bot_id)
      response = get "deleteScaleEngine", "botId=#{bot_id}"
      msg response, Logger::DEBUG
      return response
  end

private

  def get(e=@element, params=nil)
      element = e
      element << "?uuid=#{@uuid}" unless @uuid.nil?
      element << "&#{params}" unless params.nil?
      return @http.get_json(element)
  end

  # POST method
  def post(e, json='{}')
      element = e
      element << "?uuid=#{@uuid}"
      @http.post_json(element, JSON.generate(json))
  end
  
end
end
