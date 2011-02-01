class Mu
class Netconfig
  include Helper
  
  attr_accessor :host, :username, :password, :docroot, :element, :response, :config

  def initialize(host=ENV['MU_IP'], username=ENV['MU_ADMIN_USER'], password=ENV['MU_ADMIN_PASS'])
    @host = host
    @username  = username
    @password  = password
    @docroot = "/restlet/netconfig/"
    @response = nil
    @http = HttpHelper.new(@host, @username, @password, @docroot)
    @element = "" # sticky variable will hold a default element, the last element specified
    msg "Created Netconfig API object to :#{@host}", Logger::DEBUG
  end

  # get - with no params, returns the entire netconfig json object
  #  * e = the element to retrieve (interfaces|hosts|routes, interfaces/a1 ...)
  def get(e)   
    response = @http.get_json(e)
    msg response, Logger::DEBUG
    return response
  end

  # PUT to modify netconfig element(s) to json values
  #  * json = the json string containing the modified values
  #  * e = the element to modify (interfaces|hosts|routes)
  def modify(json, e)
    response = do_modify(json, e)
    msg response, Logger::DEBUG
    return response
=begin
    jstring = json
    @element = e
    unless json.is_a? String
      jstring = JSON.generate json
    end
    response = @http.put_json(e, jstring)
    msg response, Logger::DEBUG
    return response
=end
  end

  # POST method to add a network element
  #  * json = the json string containing the element values
  #  * e = the element to create (interfaces|hosts|routes)
  def create(json, e)   
    jstring = json  
    unless json.is_a? String
      jstring = JSON.generate json
    end
    response = @http.post_json(e, jstring)
    msg response, Logger::DEBUG
    return response
  end

  # deletes the specified element
  #  * e = the element to delete
  def delete(e)
    response = @http.delete(e)
    msg response, Logger::DEBUG
    return response
  end

  # updates a network configuration from file
  #  * filepath = the path to the json file
  #  * clear_existing - boolean determining whether or not existing elements should be cleared
  def restore(filepath=nil,clear_existing=false)
    unless filepath.nil?
      @config = JSON.parse(File.read(filepath))
    end
    @config.each do |c|
      case c.keys[0]
      when "hosts"
        msg "RESTORE HOSTS", Logger::DEBUG
        clear_existing and clear_hosts
        restore_hosts c["hosts"]
      when "routes"
        msg "RESTORE ROUTES", Logger::DEBUG
        clear_existing and clear_routes
        restore_routes c["routes"]
      when "interfaces"
        clear_existing and clear_vlans
        msg "RESTORE INTERFACES", Logger::DEBUG
        restore_interfaces c["interfaces"]
      end
    end
  end

  # clears the network hosts
  def clear_hosts    
    h = get("hosts")
    h["hosts"].each do |h|
      msg "Clear host: #{h['name']}", Logger::DEBUG
      delete("hosts/#{h['name']}")
    end
  end

  # restores the network hosts to the initial system states
  def restore_hosts(hosts)  
    hosts.each do |h|
      msg "create host: #{h['name']}", Logger::DEBUG
      delete "hosts/#{h['name']}" # harmlessly fails when host does not exist
      create(h,"hosts")
    end
  end

  # use Dns to update host ip addresses.
  # A new Host is added if not present when the name is provided as argument
  #  * name = the name of the host to resolve
  def resolve_hosts(name=nil)  
    hosts = Array.new
    if name.nil?
      hst = get "hosts"
      hst["hosts"].each {|h| hosts << h["name"]}
    else
      hosts << name
    end
    hosts.each do |h|
      msg "resolve host: #{h}", Logger::DEBUG
      v4_addr = Socket::gethostbyname(h)[3].unpack("CCCC").join(".") rescue nil
      next if v4_addr.nil?
      json = get "hosts/#{h}"
      if json["name"].nil?
        json = {"name" => h, "v4_addr" => v4_addr}
        create json, "hosts"
      else
        json["v4_addr"] = v4_addr
        modify json, "hosts/#{h}"
      end
    end
  end

  # clears a network interface
  #  * interface = the name of the interface to clear
  def clear_interface(interface)
    interface = interface
    json = { "v4_addrs"=>[], "v4_mask"=>"", "v4_dhcp"=>false,
      "v6_global_addrs"=>[], "v6_global_mask"=>""}
    modify json,"interfaces/#{interface}"
  end

  # clears all network vlans
  def clear_vlans
    i = get "interfaces"
    i["interfaces"].each do |i|
      next if i['vlan'] == ""
      msg "Clear vlan: #{i['name']}", Logger::DEBUG
      delete "interfaces/#{i['name']}"
    end
  end

  # restores network interfaces to system initial settings
  #   * interfaces - the names of the interfaces to restore
  def restore_interfaces(interfaces)  
    interfaces.each do |i|
      next if i['name'].include? "eth" # don't do eth0 or eth1
      msg "configure interface: #{i['name']}", Logger::DEBUG
      unless i['vlan'] == ""
        interface,vlan = i['name'].split(".")
        create [{"name"=>interface,"vlan"=>vlan},"interfaces"]
      end
      modify [i,"interfaces/#{i['name']}"]
    end
  end

  # clears network routes
  def clear_routes  
    routes = get "routes"
    routes["routes"].each do |r|
      next if r['readonly'] == true
      msg "Clear route: #{r['dst']}-#{r['gateway']}-#{r['interface_display_name'].downcase}", Logger::DEBUG
      delete "routes/#{r['dst']}-#{r['gateway']}-#{r['interface_display_name'].downcase}"
    end
  end

  # restores network routes to system initial settings
  def restore_routes(routes)  
    routes.each do |r|
      next if r['readonly'] == true
      msg "configure route: #{r['dst']}-#{r['gateway']}-#{r['interface_display_name'].downcase}", Logger::DEBUG
      create r,"routes"
    end
  end

  # writes the json config to filepath
  #  * e = the element to save, or 'all'
  #  * filepath - the fully qualified name of the file to save to
  def save(e="all", filepath="config.json")   
    json = get e
    File.open(filepath,'w'){|f| f.write(JSON.pretty_generate(json))}
  end

private

# restclient put was not recgonized as json
# PUT to modify netconfig element(s) to json values
  def do_modify(json, e)
    jstring = json
    unless json.is_a? String
      jstring = JSON.generate json
    end
    msg jstring, Logger::DEBUG
    uri = URI.parse("https://#{@host}")
    escaped = URI.escape("#{@docroot}#{e}")
    msg "Put: #{uri}#{escaped}", Logger::DEBUG
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    http.start do |http|
      req = Net::HTTP::Put.new("#{escaped}",initheader = {"User-Agent" => @username, 'Content-Type' => 'application/json; charset=utf-8'})
      req.body = jstring
      response = http_request(http, req)
    end
    msg response, Logger::DEBUG
    return response
  end

  def http_request(http, req)
    req.basic_auth(@username, @password)
    response = http.request(req)
    if response.code != "200"
      return "Error status code #{response.code}\n#{response.body}"
    end
    return response.body
  end


end 
end # Mu


