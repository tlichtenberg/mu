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

  # --------------- RestClient methods ---------------------

  #  ------- gets ---------

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

  #  ------- posts ---------

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

  def post_form(e, filepath, filename, p = {})
    url = "https://#{@username}:#{@password}@#{@host}#{@docroot}#{e}"
    params = {}.merge! p
    params = { :content_type => "multipart/form-data", :file => File.new(filepath), :name => filename }
    resp = RestClient.post(url, params)
    $cookie = resp.cookies unless resp.cookies.empty?
     msg "got cookie #{$cookie}", Logger::DEBUG unless resp.cookies.empty?
    return resp
  end

  #  ------- other ---------

  def delete(e)
    url = "https://#{@username}:#{@password}@#{@host}#{@docroot}#{e}"
    return RestClient.delete(url)
  end

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
