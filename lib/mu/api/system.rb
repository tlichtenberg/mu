class Mu
class System
  include Helper

  attr_accessor :host, :docroot, :username, :password

  def initialize(host=ENV['MU_IP'], username=ENV['MU_ADMIN_USER'], password=ENV['MU_ADMIN_PASS'])
    @host = host
    @username  = username
    @password  = password
    @docroot = "/api/v5/system/"
    @cookie = ""
    @response = nil
    @http = HttpHelper.new(@host, @username, @password, @docroot)
    msg "Created System Api object to :#{@host}", Logger::DEBUG
  end

  # restarts the Mu system
  def restart
    response = @http.get("restart/")
    msg response, Logger::DEBUG
    return response
  end

  # returns Mu System status
  def status
    response =  @http.get("status/")
    msg response, Logger::DEBUG
    return response
  end

  # returns more Mu System status
  def status2
    response = @http.get("status2/")
    msg response, Logger::DEBUG
    return response
  end
 
end 
end # Mu
