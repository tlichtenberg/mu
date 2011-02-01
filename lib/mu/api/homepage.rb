class Mu
class Homepage
  include Helper
  
  attr_accessor :host, :docroot, :cookie, :username, :password, :session_id, :results, :posted_uuid, :testsuite, :results, :failed, :errors
  
  def initialize(host=ENV['MU_IP'], username=ENV['MU_ADMIN_USER'], password=ENV['MU_ADMIN_PASS'])
    @host = host
    @username  = username
    @password  = password
    @docroot = "/api/v5/homepage/"
    @cookie = ""
    @response = nil
    @http = HttpHelper.new(@host, @username, @password, @docroot)
    msg "Created Homepage object to :#{@host}", Logger::DEBUG
  end

  # returns all homepage elements
  def all
    response = @http.get("all/")
    msg response, Logger::DEBUG
    return response
  end

  # returns recent homepage activity
  def recent
    response = @http.get("recent/")
    msg response, Logger::DEBUG
    return response
  end

  # returns homepage status
  def status
    response = @http.get("status/")
    msg response, Logger::DEBUG
    return response
  end

  # returns the latest test
  def latest_test
    response = @http.get("test/latest/")
    msg response, Logger::DEBUG
    return response
  end

  # returns queued tests
  def queue_test
    response = @http.get("test/queue/")
    msg response, Logger::DEBUG
    return response
  end

end 
end # Mu
