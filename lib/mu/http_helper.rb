class Mu
class HttpHelper
  include Helper

  def initialize(host, username, password, docroot)
    @host = host
    @username = username
    @password = password
    @docroot = docroot
    $cookie = "" if $cookie.nil?
  end

  #--------------- RestClient methods ---------------------

  # basic get call
  #  * e = the url suffix
  #  * p = hash of parameters, such as headers
  def get(e, p={})
    url = "https://#{@username}:#{@password}@#{@host}#{@docroot}#{e}"
    msg url, Logger::DEBUG
    params = {}.merge! p
    params[:cookies] = $cookie if !$cookie.empty?
    resp = RestClient.get(url, params)
    $cookie = resp.cookies unless resp.cookies.empty?
    msg "got cookie #{$cookie}", Logger::DEBUG unless resp.cookies.empty?
    return resp
  end

  # get call for json, converts the response to json if applicable
  #  * e = the url suffix
  #  * p = hash of parameters, such as headers
  def get_json(e, p={})
    url = "https://#{@username}:#{@password}@#{@host}#{@docroot}#{e}"
    msg url, Logger::DEBUG
    params = {}.merge! p
    params[:cookies] = $cookie if !$cookie.empty?
    resp = RestClient.get(url, params)
    $cookie = resp.cookies unless resp.cookies.empty?
    msg "got cookie #{$cookie}", Logger::DEBUG unless resp.cookies.empty?
    begin
      msg resp, Logger::DEBUG
      jresp = JSON resp
      if jresp
        return jresp
      end
    rescue JSON::ParserError => e
       # nothing to do
    end
    return resp
  end

  # get call for xml, converts the response to xml if applicable
  #  * e = the url suffix
  #  * p = hash of parameters, such as headers
  def get_xml(e, p={})
    url = "https://#{@username}:#{@password}@#{@host}#{@docroot}#{e}"
    msg url, Logger::DEBUG
    params = {}.merge! p
    params[:cookies] = $cookie if !$cookie.empty?
    resp = RestClient.get(url, params)
    $cookie = resp.cookies unless resp.cookies.empty?
    msg "got cookie #{$cookie}", Logger::DEBUG unless resp.cookies.empty?
    msg resp, Logger::DEBUG
    begin
      if (/<.+>/).match(resp)
        xmldoc = Nokogiri::XML(resp)
      else
        err_node = Nokogiri::XML::Node.new('err_node', xmldoc)
        err_node.content = resp
        xmldoc.root << err_node
      end
    rescue =>  e
      msg "Error parsing XML " + e.to_s, Logger::DEBUG
    ensure
      msg xmldoc, Logger::DEBUG
      return xmldoc
    end
  end

  # basic post call
  #  * e = the url suffix
  #  * body = the data to post
  #  * p = hash of parameters, such as headers
  def post(e, body="", p = {})
    url = "https://#{@username}:#{@password}@#{@host}#{@docroot}#{e}"
    msg "#{url}  #{body}", Logger::DEBUG
    params = {}.merge! p
    params[:cookies] = $cookie if !$cookie.empty?
    msg("using cookie #{$cookie}", Logger::DEBUG) if !$cookie.empty?  
    resp = RestClient.post(url, body, params)
    # msg resp.headers
    $cookie = resp.cookies unless resp.cookies.empty?
    msg "got cookie #{$cookie}", Logger::DEBUG unless resp.cookies.empty?
    begin
      msg resp, Logger::DEBUG
      jresp = JSON resp
      if jresp
        return jresp
      end
    rescue JSON::ParserError => e
       # do nothing
    end
    return resp
  end

  #  post call for uploading json
  #  * e = the url suffix
  #  * body = the json object to post
  #  * p = hash of parameters, such as headers
  def post_json(e, json, p = {})
     url = "https://#{@username}:#{@password}@#{@host}#{@docroot}#{e}"
     msg "#{url}  #{json}", Logger::DEBUG
     params = { :content_type => "application/json" }.merge! p
     params[:cookies] = $cookie if !$cookie.empty?
     resp = RestClient.post(url, json, params  )
     begin
      msg resp, Logger::DEBUG
      $cookie = resp.cookies unless resp.cookies.empty?
      msg "got cookie #{$cookie}", Logger::DEBUG unless resp.cookies.empty?
      jresp = JSON resp
      if jresp
        return jresp
      end
    rescue JSON::ParserError => e
       # msg e, Logger::DEBUG
    end
    return resp
  end

  #  post call for uploading xml
  #  * e = the url suffix
  #  * body = the xml object to post
  #  * p = hash of parameters, such as headers
  def post_xml(e, doc, p = {})
    begin
      url = "https://#{@username}:#{@password}@#{@host}#{@docroot}#{e}"
      msg "post to #{url}", Logger::DEBUG
      params = { :content_type => "application/xml" }.merge! p
      params[:cookies] = $cookie if !$cookie.empty?
      resp = RestClient.post(url, doc.to_s, params )
      msg resp, Logger::DEBUG
      $cookie = resp.cookies unless resp.cookies.empty?
      msg "got cookie #{$cookie}", Logger::DEBUG unless resp.cookies.empty?
      # XML Document
      if (/<.+>/).match(resp)
        xmldoc = Nokogiri::XML(resp)
      else
        err_node = Nokogiri::XML::Node.new('err_node', xmldoc)
        err_node.content = resp
        xmldoc.root << err_node
      end
    rescue SocketError
      raise "Host " + @host + " nicht erreichbar"
    rescue Exception => e
      msg "error parsing XML " + e.to_s, Logger::DEBUG
    end
    if (xmldoc.nil? || !xmldoc.xpath("//err_node").empty?)
      @posted_uuid = nil
    end
    if !xmldoc.nil?
      @posted_uuid = xmldoc.xpath("//uuid")[0].text if !xmldoc.xpath("//uuid").empty?
    end
    return xmldoc
  end

  #  post call for uploading form data
  #  * e = the url suffix
  #  * filepath = the file to post
  #  * p = hash of parameters, such as headers
  def post_form(e, filepath, p = {})
    url = "https://#{@username}:#{@password}@#{@host}#{@docroot}#{e}"
    params = {}.merge! p
    params = { :content_type => "application/x-www-form-urlencoded", :file => File.new(filepath, 'rb') }
    resp = RestClient.post(url, params)
    $cookie = resp.cookies unless resp.cookies.empty?
    msg "got cookie #{$cookie}", Logger::DEBUG unless resp.cookies.empty?
    return resp
  end

  #------- other ---------

  # basic delete call
  #  * e = the url suffix
  def delete(e)
    url = "https://#{@username}:#{@password}@#{@host}#{@docroot}#{e}"
    return RestClient.delete(url)
  end

  # put call for json
  #  * e = the url suffix
  #  * body = the json object to put
  #  * p = hash of parameters, such as headers
  def put_json(e, json, p={})
     url = "https://#{@username}:#{@password}@#{@host}#{@docroot}#{e}"
     params = {}.merge! p
     params[:cookies] = $cookie if !$cookie.empty?
     resp = RestClient.put(url, json, { :content_type => "application/json" } )
     begin
      msg resp, Logger::DEBUG
      $cookie = resp.cookies unless resp.cookies.empty?
      msg "got cookie #{$cookie}", Logger::DEBUG unless resp.cookies.empty?
      jresp = JSON resp
      if jresp
        return jresp
      end
    rescue JSON::ParserError => e
       # msg e, Logger::DEBUG
    end
    return resp
  end

  # fetches a file and stores it locally
  #  * e = the url suffix
  #  * filename = the name to store the file locally
  #  * p = hash of parameters, such as headers
  def download_file(e, filename, p={})
    url = "https://#{@username}:#{@password}@#{@host}#{@docroot}#{e}"
    params = {}.merge! p
    params[:cookies] = $cookie if !$cookie.empty?
    resp = RestClient.get(url)
    $cookie = resp.cookies unless resp.cookies.empty?
    msg "got cookie #{$cookie}", Logger::DEBUG unless resp.cookies.empty?
    if resp.body.include?("Could not download")
        msg "==> Could not download the file"
        return -1
    end
    open(filename, "wb") { |f| f.write(resp.body) }
    return File.size(filename)
  end

end
end # Mu
