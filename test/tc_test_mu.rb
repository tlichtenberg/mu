require 'rubygems'
require 'test/unit'
require 'lib/mu'
require 'json'

class Object
  def deep_clone
    Marshal::load(Marshal.dump(self))
  end
end

class TCTestMu < Test::Unit::TestCase

  $dir = Dir.pwd

  
  
  def setup
      $log.level = Logger::INFO
      @mu_ip = ENV['MU_IP']
      @mu_admin_user = ENV['MU_ADMIN_USER']
      @mu_admin_pass = ENV['MU_ADMIN_PASS']
      Dir.chdir($dir)
      $cookie = nil # reset for htto_helper
      # puts "pwd = #{Dir.pwd}"
  end

  def teardown
   
  end

  # -------------- cmd_appid ----------------

  # use ip range setting and a brief pattern
  def test_cmd_appid_run_file
      File.delete("app_id_status.json") if File.exists?("app_id_status.json")
      app = Mu::Command::Cmd_appid.new
      args = Array.new
      args << "-s"
      args << "#{Dir.pwd}/test/data/data_cgi.msl"
      args << "-i"
      args << "b1-10000,b2"
      args << "-p"
      args << "1-100:10"
      app.cmd_run_file args
      assert(File.exists?("app_id_status.json"), "app_id_status.json file was not created")
      j = JSON File.read("app_id_status.json")
      status = j["status"]
      assert(status["statistics"]["summary"]["duration"].to_f >= 10.0, "expected summary duration > 10, but got #{status["statistics"]["summary"]["duration"]}")
      assert(status["statistics"]["summary"]["instances"]["executed"].to_i > 10, "expected instances executed > 0, but got #{status["statistics"]["summary"]["instances"]["executed"]}")
  end

  # use ip range setting and a brief pattern
  def test_cmd_appid_run_dir
      File.delete("app_id_status.json") if File.exists?("app_id_status.json")
      app = Mu::Command::Cmd_appid.new
      args = Array.new
      args << "-d"
      args << "#{Dir.pwd}/test/data"
      args << "-i"
      args << "b1-10000,b2"
      args << "-p"
      args << "1-100:10"
      app.cmd_run_dir args
      sleep 2
      assert(File.exists?("app_id_status.json"), "app_id_status.json file was not created")
      j = JSON File.read("app_id_status.json")
      status = j["status"]
      assert(status["statistics"]["summary"]["duration"].to_f >= 10.0, "expected summary duration > 10, but got #{status["statistics"]["summary"]["duration"]}")
      assert(status["statistics"]["summary"]["instances"]["executed"].to_i > 10, "expected instances executed > 0, but got #{status["statistics"]["summary"]["instances"]["executed"]}")
  end
  

  # -------------- cmd_cli ----------------

  def test_cli_history
      api = Mu::Command::Cmd_cli.new
      result = api.cmd_history []
      puts result
      assert result==true, "expected 'true'"
  end

  def test_cli_question
      api = Mu::Command::Cmd_cli.new
      result = api.cmd_question []
      puts result
      assert result==true, "expected 'true'"
  end

  # -------------- cmd_ddt --------------

  def test_cmd_ddt_get_all_sessions
      api = Mu::Command::Cmd_ddt.new
      api.cmd_close_all_sessions []
      api.cmd_new_session []
      api.cmd_new_session []
      sessions = Nokogiri::XML(api.cmd_get_all_sessions [])
      sess = sessions.xpath("//session")
      assert(sess.length == 2, "expected 2 sessions, got #{sess.length}")
  ensure
      api.cmd_close_all_sessions []
  end

  def test_cmd_ddt_csv_import_export
      api = Mu::Command::Cmd_ddt.new
      api.cmd_close_all_sessions []
      api.cmd_new_session []
      response = Nokogiri::XML(api.cmd_csv_import [ "-t", "#{Dir.pwd}/test/data/default_test.csv"])
      status = response.xpath("//status")[0].content
      assert(status == "true", "expected status=true, got #{status}")
      uuid = response.xpath("//message")[0].content
      response = Nokogiri::XML(api.cmd_csv_export ["-u", uuid ])
      status = response.xpath("//status")[0].content
      assert(status == "true", "expected status=true, got #{status}")
  ensure
      api.cmd_close_all_sessions []
  end

  def test_cmd_ddt_get_set_options
      scenario_uuid = "ef6fe3eb-4e9f-44b5-a99e-c431d82e4eeb"
      #test_set_uuid = "49cd406e-a8ca-4360-a115-e7ac33e8034f"
      api = Mu::Command::Cmd_ddt.new
      api.cmd_close_all_sessions []
      api.cmd_new_session []
      http_helper = Mu::HttpHelper.new(@mu_ip, @mu_admin_user, @mu_admin_pass, "/api/v3/")
      http_helper.post_xml("templates/import", File.read("#{Dir.pwd}/test/data/data_cgi.xml"))
     # http_helper.post_xml("templates/import", File.read("#{Dir.pwd}/test/data/test_data_cgi_error.xml"))
      api.cmd_load_scenario [ "-u", scenario_uuid ]
      api.cmd_setup_test []
      response = api.cmd_get_options []
      doc = Nokogiri::XML(response)
      options = doc.xpath("//option/name")
      assert options.length==8, "expected 8 scenario options, found #{options.length}"
      response = api.cmd_set_options [ "-n", "scenario_user_options.url", "-p", "hullo" ]
      response.each do | resp |
        doc = Nokogiri::XML(resp)
        message = doc.xpath("//message").text
        assert message.include?("Option set") , "expected 'Option set' but got #{message}"
      end
  ensure
      api.cmd_close_all_sessions []
  end

  def test_cmd_ddt_get_set_hosts
      scenario_uuid = "ef6fe3eb-4e9f-44b5-a99e-c431d82e4eeb"
      api = Mu::Command::Cmd_ddt.new
      api.cmd_close_all_sessions [ "-v" ]
      api.cmd_new_session []
      http_helper = Mu::HttpHelper.new(@mu_ip, @mu_admin_user, @mu_admin_pass, "/api/v3/")
      http_helper.post_xml("templates/import", File.read("#{Dir.pwd}/test/data/data_cgi.xml"))
      api.cmd_load_scenario [ "-u", scenario_uuid ]
      api.cmd_setup_test []
      response = api.cmd_get_hosts []
      doc = Nokogiri::XML(response)
      hosts = doc.xpath("//host")
      role = doc.xpath("//host/role")[0].text
      assert hosts.length==2, "expected 2 scenario hosts, found #{hosts.length}"
      response = api.cmd_set_hosts [ "-r", role, "-n", "a3" ]
      response.each do | resp |
        doc = Nokogiri::XML(resp)
        message = doc.xpath("//message").text
        assert message.include?("Bind host successfully") , "expected 'Bind host successfully' but got #{message}"
      end
  ensure
      api.cmd_close_all_sessions []
  end

  def test_cmd_ddt_get_set_channels
      add_localhost_with_channel
      scenario_uuid = "379a4cf8-8fe7-4d2d-8f6b-b8c6b71557b4"  # ftp_with_channel
      api = Mu::Command::Cmd_ddt.new
      api.cmd_close_all_sessions [ "-v" ]
      api.cmd_new_session []
      http_helper = Mu::HttpHelper.new(@mu_ip, @mu_admin_user, @mu_admin_pass, "/api/v3/")
      http_helper.post_xml("templates/import", File.read("#{Dir.pwd}/test/data/ftp_with_channel.xml"))
      api.cmd_load_scenario [ "-u", scenario_uuid ]
      api.cmd_setup_test []
      response = api.cmd_get_channels []
      doc = Nokogiri::XML(response)
      channels = doc.xpath("//channel")
      assert channels.length==1, "expected 1 scenario channel, found #{channels.length}"
      response = api.cmd_set_channels [ "-r", "channel", "-n", "localhost" ]
      response.each do | resp |
        doc = Nokogiri::XML(resp)
        message = doc.xpath("//message").text
        assert message.include?("Bind channel successfully") , "expected 'Bind host successfully' but got #{message}"
      end
  ensure
      api.cmd_close_all_sessions []
  end

  # -------------- ddt ------------------

  def test_ddt_new
      api = Mu::Ddt.new(@mu_ip, @mu_admin_user, @mu_admin_pass)
      assert(api.host == @mu_ip, "failed to set mu_ip")
      assert(api.docroot == "/api/v5/ddt/", "failed to set docroot")
  end

  def test_ddt_get_all_sessions
      api = Mu::Ddt.new(@mu_ip, @mu_admin_user, @mu_admin_pass)
      api.new_session
      api.new_session
      sessions = Nokogiri::XML(api.get_all_sessions)
      sess = sessions.xpath("//session")
      assert(sess.length == 2, "expected 2 sessions, got #{sess.length}")
  ensure
      api.close_all_sessions
  end

  def test_ddt_close_all_sessions
      api = Mu::Ddt.new(@mu_ip, @mu_admin_user, @mu_admin_pass)
      api.new_session
      api.new_session
      api.new_session
      api.close_all_sessions
      sessions = Nokogiri::XML(api.get_all_sessions)
      sess = sessions.xpath("//session")
      assert(sess.length == 0, "expected 0 sessions, got #{sess.length}")
  end

  def test_ddt_set_hosts
      $log.level = Logger::DEBUG
      data_cgi_uuid = "ef6fe3eb-4e9f-44b5-a99e-c431d82e4eeb"
      api = Mu::Ddt.new(@mu_ip, @mu_admin_user, @mu_admin_pass)
      api.new_session
      http_helper = Mu::HttpHelper.new(@mu_ip, @mu_admin_user, @mu_admin_pass, "/api/v3/")
      http_helper.post_xml("templates/import", File.read("#{Dir.pwd}/test/data/data_cgi.xml"))
      api.load_scenario(data_cgi_uuid)
      api.setup_test
      response = api.set_hosts( ["192.168.40.217","192.168.40.9"], ["a1", "a2"] )
      response.each do | resp |
        doc = Nokogiri::XML(resp)
        message = doc.xpath("//message").text
        assert message.include?("Bind host successfully") , "expected 'Bind host successfully' but got #{message}"
      end
  ensure
      api.close_all_sessions
  end

  # -------------- cmd_homepage -------------

  def test_homepage_status
      api = Mu::Command::Cmd_homepage.new
      result = JSON api.cmd_status []
      assert result[0]["title"] == "Licenses", "expected 'Licenses'"
  end

  def test_homepage_recent
      api = Mu::Command::Cmd_homepage.new
      result = JSON api.cmd_recent []
      assert !result[0]["summary"].nil?, "expected to find a summary field but didn't"
  end

  def test_homepage_all
      api = Mu::Command::Cmd_homepage.new
      result = JSON api.cmd_all []
      assert !result["status"].nil?, "expected to find a status field but didn't"
  end

  def test_homepage_latest_test
      api = Mu::Command::Cmd_homepage.new
      result = JSON api.cmd_latest_test []
      assert  !result.nil?, "expected to get something back but didn't"
  end
  
  # -------------- homepage -------------

  def test_homepage_new
      api = Mu::Homepage.new(@mu_ip, @mu_admin_user, @mu_admin_pass)
      assert(api.host == @mu_ip, "failed to set mu_ip")
      assert(api.docroot == "/api/v5/homepage/", "failed to set docroot")
  end

  # -------------- cmd_muapi ------------

  def test_cmd_muapi_types
      api = Mu::Command::Cmd_muapi.new
      response = api.cmd_types []
      assert(response.include?("scenario"), "expected scenario got #{response}")
  end

  def test_cmd_muapi_export_by_uuid
     api = Mu::Command::Cmd_muapi.new
     scenario_uuid = "379a4cf8-8fe7-4d2d-8f6b-b8c6b71557b4"  # ftp_with_channel
     http_helper = Mu::HttpHelper.new(@mu_ip, @mu_admin_user, @mu_admin_pass, "/api/v3/")
     http_helper.post_xml("templates/import", File.read("#{Dir.pwd}/test/data/ftp_with_channel.xml"))
     response = api.cmd_export_by_uuid(["-u", scenario_uuid]).to_s
     assert response.include?(scenario_uuid), "expected #{scenario_uuid} but did not find it"
  end

  def test_cmd_muapi_export_by_type_and_name
     api = Mu::Command::Cmd_muapi.new
     scenario_uuid = "379a4cf8-8fe7-4d2d-8f6b-b8c6b71557b4"  # ftp_with_channel
     http_helper = Mu::HttpHelper.new(@mu_ip, @mu_admin_user, @mu_admin_pass, "/api/v3/")
     http_helper.post_xml("templates/import", File.read("#{Dir.pwd}/test/data/ftp_with_channel.xml"))
     response = api.cmd_export_by_type_and_name(["-n", "ftp_with_channel", "-t", "scenario"]).to_s
     assert response.include?(scenario_uuid), "expected #{scenario_uuid} but did not find it"
  end

  def test_cmd_muapi_capture
      api = Mu::Command::Cmd_muapi.new
      run_args = Array.new
      run_args << "-c"
      run_args << "run"
      run_args << "-p"
      run_args << "a1"
      job_id = api.cmd_capture run_args
      sleep 2
      status_args = Array.new
      status_args << "-c"
      status_args << "status"
      status_args << "-p"
      status_args << "a1"
      status_args << "-u"
      status_args << job_id
      status = api.cmd_capture status_args
      sleep 2
      get_args = Array.new
      get_args << "-c"
      get_args << "get"
      get_args << "-p"
      get_args << "a1"
      get_args << "-u"
      get_args << job_id
      api.cmd_capture get_args
      sleep 2
      assert( File.exists?("#{job_id}.pcap"), "expected to find #{job_id}.pcap but didn't")
  end

  def test_cmd_muapi_analysis
      # $log.level = Logger::DEBUG
      http_helper = Mu::HttpHelper.new(@mu_ip, @mu_admin_user, @mu_admin_pass, "/api/v3/")
      response = http_helper.post_xml("templates/import", File.read("#{Dir.pwd}/test/data/irc.xml"))
      uuid = response.xpath("//uuid")[0].content
      api = Mu::Command::Cmd_muapi.new
      
      run_uuid = api.cmd_run make_uuid_args(uuid) # use the run_uuid for subsequent calls
      sleep 2
      status = api.cmd_status make_uuid_args(run_uuid)
      assert(status == "RUNNING", "after RUN, expected status=RUNNING, got #{status}")
      api.cmd_pause make_uuid_args(run_uuid)
      while true
        sleep 2
        status = api.cmd_status make_uuid_args(run_uuid)
        break if status == "SUSPENDED"        
      end
      api.cmd_resume make_uuid_args(run_uuid)   
      while true
        sleep 2
        status = api.cmd_status make_uuid_args(run_uuid)      
        break if status == "RUNNING"     
      end
      list = api.cmd_list_by_status ["-s", "running"]
      assert(list.to_s.include?(run_uuid), "expected run_uuid #{run_uuid}in the list_by_status for running, but got #{list}")
      api.cmd_stop make_uuid_args(run_uuid)
      sleep 2
      status = api.cmd_status make_uuid_args(run_uuid)
      assert(status == "ABORTED", "after STOP, expected status=ABORTED, got #{status}")
      name = api.cmd_get_name make_uuid_args(run_uuid) # returns a Nokogiri::XML::Attr
      assert(name.value.include?("irc_scenario_mugem"), "expected name = irc_scenario_mugem but got #{name.value}")
  ensure
    begin
      api.cmd_stop make_uuid_args(run_uuid)
    rescue
      # do nothing. probably already stopped
    end
  end

  def make_uuid_args(uuid)
    args = Array.new
    args << "-u"
    args << uuid
    args << "-v"
    return args
  end

  def test_cmd_muapi_archive
      # $log.level = Logger::DEBUG
      # load it
      http_helper = Mu::HttpHelper.new(@mu_ip, @mu_admin_user, @mu_admin_pass, "/api/v3/")
      response = http_helper.post_xml("templates/import", File.read("#{Dir.pwd}/test/data/irc.xml"))
      uuid = response.xpath("//uuid")[0].content
      api = Mu::Command::Cmd_muapi.new

      # run it
      run_uuid = api.cmd_run make_uuid_args(uuid) # use the run_uuid for subsequent calls
      sleep 2
      status = api.cmd_status make_uuid_args(run_uuid)
      assert(status == "RUNNING", "after RUN, expected status=RUNNING, got #{status}")
      while status == "RUNNING" 
        sleep 5
        status = api.cmd_status make_uuid_args(run_uuid)
      end

      # archive it
      response = api.cmd_archive ["-c", "run", "-u", run_uuid ]
      sleep 5
      status = api.cmd_archive ["-s", "status", "-u", run_uuid ]

      while true
        status = api.cmd_archive ["-s", "status", "-u", run_uuid ]
        break if status == false
        sleep 5
      end

      # now get it
      api.cmd_archive ["-c", "get", "-u", run_uuid ]
      file_name = run_uuid.to_s + ".zip"
      assert(File.exists?(file_name), "did not find the expected file #{file_name}")
  end

  def test_cmd_muapi_delete
      # $log.level = Logger::DEBUG"
      # load it
      http_helper = Mu::HttpHelper.new(@mu_ip, @mu_admin_user, @mu_admin_pass, "/api/v3/")
      response = http_helper.post_xml("templates/import", File.read("#{Dir.pwd}/test/data/irc.xml"))
      uuid = response.xpath("//uuid")[0].content
      api = Mu::Command::Cmd_muapi.new

      # run it
      run_uuid = api.cmd_run make_uuid_args(uuid) # use the run_uuid for subsequent calls
      sleep 2
      status = api.cmd_status make_uuid_args(run_uuid)
      assert(status == "RUNNING", "after RUN, expected status=RUNNING, got #{status}")
      while status == "RUNNING"
        sleep 5
        status = api.cmd_status make_uuid_args(run_uuid)
      end

      # now delete it
      status = api.cmd_delete [ "-u", run_uuid ]
      puts status

      status = api.cmd_status make_uuid_args(run_uuid)
      assert(status.nil?, "expected status=nil, got #{status}")
  end

  # -------------- muapi ----------------

  def test_muapi_new
      api = Mu::Muapi.new(@mu_ip, @mu_admin_user, @mu_admin_pass)
      assert(api.host == @mu_ip, "failed to set mu_ip")
      assert(api.docroot == "/api/v3/", "failed to set docroot")
  end

  def test_muapi_list_by_status
      api = Mu::Muapi.new(@mu_ip, @mu_admin_user, @mu_admin_pass)
      response = api.list_by_status("finished")
      assert(!response.empty?, "got empty response")
  end

  def test_muapi_types
      api = Mu::Muapi.new(@mu_ip, @mu_admin_user, @mu_admin_pass)
      response = api.types
      assert(response.include?("scenario"), "expected scenario, got\n#{response}")
  end
  
  # -------------- cmd_netfconfig -------

  def test_cmd_netconfig_get_interfaces_a1
      api = Mu::Command::Cmd_netconfig.new
      response = api.cmd_get ["-e", "interfaces/a1"]
      assert(response["display_name"] == "A1", "expected A1 got #{response["display_name"]}")
  end

  def test_cmd_netconfig_modify_interfaces_a1
      # $log.level = Logger::DEBUG
      api = Mu::Command::Cmd_netconfig.new
      saved = api.cmd_get ["-e", "interfaces/a1"]
      assert(saved["display_name"] == "A1", "expected A1 got #{saved["display_name"]}")
      api.cmd_modify ["-e", "interfaces/a1", "-j", '{"v4_dhcp"=>false}']
      sleep 2
      modified = api.cmd_get ["-e", "interfaces/a1"]
      assert(modified["v4_dhcp"] == false, "expected dhcp false but it wasn't")
  ensure
      api.cmd_modify ["-e", "interfaces/a1", "-j", '{"v4_dhcp"=>true}']
  end

  def test_cmd_netconfig_vlans
     # $log.level = Logger::DEBUG
      api = Mu::Command::Cmd_netconfig.new
      begin
         api.cmd_delete ["-e", "interfaces/b1.222"]
      rescue
        # ignore. the vlan probably did not exist
      end
      vlan_222 = {"v4_addrs"=>["2.2.2.2"],"v4_mask"=>"26","v6_addrs"=>["2222:0:0:0:0:0:0:2"],"v6_mask"=>"64"}
      api.cmd_create ["-j", '{"name"=>"b1","vlan"=>"222"}', "-e", "interfaces" ]
      sleep 3
      api.cmd_modify [ "-j", vlan_222, "-e", "interfaces/b1.222"]
      b1 = api.cmd_get ["-e", "interfaces/b1.222"]
      assert(b1["v4_addrs"]["begin"] == "2.2.2.2","vlan v4_addrs incorrect: #{b1["v4_addrs"]["begin"]}")
      response = api.cmd_delete ["-e", "interfaces/b1.222"]
      assert(response.include?("deleted"), "Failed to delete host:" + response)
  end

  def test_cmd_netconfig_create_delete_host
      # $log.level = Logger::DEBUG
      api = Mu::Command::Cmd_netconfig.new
      response = api.cmd_create ["-j", '{"name"=>"deleteme","v4_addr"=>"192.168.30.9"}', "-e", "hosts"]
      assert(response.include?("created"), "Failed to create host:" + response.to_s)
      response = api.cmd_delete ["-e", "hosts/deleteme"]
      assert(response.include?("deleted"), "Failed to delete host:" + response.to_s)
  end

  def test_cmd_netconfig_add_modify_delete_route
      puts "assumes a1 on 192.168.30.x subnet and a router at 192.168.30.247"
      # $log.level = Logger::DEBUG
      api = Mu::Command::Cmd_netconfig.new
      system = api.cmd_get ["-e", "system"]
      # delete route if if already existsname"] ==
      begin
        response = api.cmd_delete ["-e", "routes/192.168.100.0-192.168.30.247-a1"]
      rescue
        # do nothing. route may not exists
      end
      # turn dhcp on
      dhcp = {"name"=>"a1","v4_dhcp"=>"Enabled"}
      response = api.cmd_modify ["-j", dhcp, "-e", "interfaces/a1"]
      sleep 3
      g = api.cmd_get ["-e", "interfaces/a1"]
      assert(g["v4_addrs"]["begin"].include?("192.168.30"),"A1 DHCP failed")
      new_route = {"interface"=>"a1", "dst"=>"192.168.100.0", "gateway"=>"192.168.30.247", "dst_pfx_len"=>24}
      response = api.cmd_create ["-j", new_route, "-e", "routes"]
      assert(response.include?("192.168.100.0-192.168.30.247-a1 created."), response) # not sure what this will be
      update_mask = {"dst_pfx_len"=>24}
      response = api.cmd_modify ["-j", update_mask, "-e", "routes/192.168.100.0-192.168.30.247-a1"]
  ensure
      response = api.cmd_delete ["-e", "routes/192.168.100.0-192.168.30.247-a1"]
      assert(response.include?("deleted"),response)
  end

  def test_cmd_netconfig_resolve_hosts
    # $log.level = Logger::DEBUG
      api = Mu::Command::Cmd_netconfig.new
      add_localhost_with_channel
      response = api.cmd_resolve_hosts ["-n", "localhost"]
      response = api.cmd_get ["-e", "hosts/localhost"]
      assert response["name"] == "localhost", "expected to find localhost but found #{response["name"]}"
  end

  def test_cmd_netconfig_save
    # $log.level = Logger::DEBUG
      api = Mu::Command::Cmd_netconfig.new
      File.delete("save.json") if File.exists?("save.json")
      response = api.cmd_save ["-f", "save.json"]
      assert(File.exists?("save.json"), "wxpected for find file 'save.json but did not")
  ensure
      File.delete("save.json") if File.exists?("save.json")
  end

  # -------------- netconfig -----------

  def test_netconfig_new
      api = Mu::Netconfig.new(@mu_ip, @mu_admin_user, @mu_admin_pass)
      assert(api.host == @mu_ip, "failed to set mu_ip")
      assert(api.docroot == "/restlet/netconfig/", "failed to set docroot")
  end

  # -------------- cmd_runscale -------------

  # use ip range setting and a brief pattern
  def test_cmd_runscale_run_file
      File.delete("app_id_status.json") if File.exists?("app_id_status.json")
      app = Mu::Command::Cmd_runscale.new
      args = Array.new
      args << "-s"
      args << "#{Dir.pwd}/test/data/data_cgi.msl"
      args << "-i"
      args << "b1-10000,b2"
      args << "-p"
      args << "1-100:10"
      app.cmd_run_file args
      assert(File.exists?("app_id_status.json"), "app_id_status.json file was not created")
      j = JSON File.read("app_id_status.json")
      status = j["status"]
      assert(status["statistics"]["summary"]["duration"].to_f >= 10.0, "expected summary duration > 10, but got #{status["statistics"]["summary"]["duration"]}")
      assert(status["statistics"]["summary"]["instances"]["executed"].to_i > 10, "expected instances executed > 0, but got #{status["statistics"]["summary"]["instances"]["executed"]}")
  end

  # use ip range setting and a brief pattern
  def test_cmd_runscale_run_dir
      File.delete("app_id_status.json") if File.exists?("app_id_status.json")
      app = Mu::Command::Cmd_runscale.new
      args = Array.new
      args << "-d"
      args << "#{Dir.pwd}/test/data"
      args << "-i"
      args << "b1-10000,b2"
      args << "-p"
      args << "1-100:10"
      app.cmd_run_dir args
      assert(File.exists?("app_id_status.json"), "app_id_status.json file was not created")
      j = JSON File.read("app_id_status.json")
      status = j["status"]
      assert(status["statistics"]["summary"]["duration"].to_f >= 10.0, "expected summary duration > 10, but got #{status["statistics"]["summary"]["duration"]}")
      assert(status["statistics"]["summary"]["instances"]["executed"].to_i > 10, "expected instances executed > 0, but got #{status["statistics"]["summary"]["instances"]["executed"]}")
  end
 

  # -------------- cmd_runscenario ----------

  def test_cmd_runscenario
      app = Mu::Command::Cmd_runscenario.new
      args = Array.new
      args << "-s"
      args << "#{Dir.pwd}/test/data/data_cgi.xml"
      args << "-i"
      args << "b1,b2"
      args << "-v"
      app.cmd_run args
      assert(app.errors.size == 0, "expected 0 errors but got #{app.errors}")
  end
  

  # -------------- cmd_runverify ------------

  def test_cmd_runverify
      app = Mu::Command::Cmd_runverify.new
      args = Array.new
      args << "-s"
      args << "#{Dir.pwd}/test/data/data_cgi.xml"
      args << "-t"
      args << "#{Dir.pwd}/test/data/default_test.csv"
      args << "-i"
      args << "b1,b2"
      args << "-v"
      app.cmd_run args
      assert(app.errors.size > 0, "expected errors but got none")
  end


  # -------------- scale ----------------

  def test_scale_new
      api = Mu::Scale.new(@mu_ip, @mu_admin_user, @mu_admin_pass)
      assert(api.host == @mu_ip, "failed to set mu_ip")
      assert(api.docroot == "/api/v5/scale/", "failed to set docroot")
      assert(!api.uuid.nil?, "uuid is nil")
  end

  def test_scale_about
      api = Mu::Scale.new(@mu_ip, @mu_admin_user, @mu_admin_pass)
      about = api.about
      # puts JSON.pretty_generate about
      assert(about[0]["group"] == "active", "expected 'active' group, got #{about[0]["group"]}")
      assert(about[0]["type"] == "bot", "expected 'bot' type, got #{about[0]["type"]}")
      assert(!api.uuid.nil?, "uuid is nil")
  end

  def test_scale_list
      api = Mu::Scale.new(@mu_ip, @mu_admin_user, @mu_admin_pass)
      list = api.list
      assert(list.length == 1 , "expected list of length 1, got #{list.length}")
      assert(!api.uuid.nil?, "uuid is nil")
  end

  def test_scale_session
      api = Mu::Scale.new(@mu_ip, @mu_admin_user, @mu_admin_pass)
      api.session
      assert(!api.uuid.nil?, "uuid is nil")
  end

  # -------------- system ---------------

  # do NOT write a test for system:restart please!

  def test_system_new
      api = Mu::System.new(@mu_ip, @mu_admin_user, @mu_admin_pass)
      assert(api.host == @mu_ip, "failed to set mu_ip")
      assert(api.docroot == "/api/v5/system/", "failed to set docroot")
  end

  # -------------- cmd_system ----------------

  # do NOT write a test for cmd_system:restart please!

  def test_cmd_system_status
      api = Mu::Command::Cmd_system.new
      result = api.cmd_status []
      doc = Nokogiri::XML(result)
      ports = doc.xpath("//ports")
      assert(ports.length >= 5, "expected to find at least 5 ports, but got #{ports.length}")
  end

  def test_cmd_system_status2
      api = Mu::Command::Cmd_system.new
      result = api.cmd_status2 []
      assert(result.to_s.include?("raid"), "expected to find 'raid' in results, but got #{result}")
  end

  #---------------------- utility methods -----------------------

  def add_localhost_with_channel
    local_host = {
        "name"=> "localhost",
        "ssh_channel"=> {
          "username"=> "root",
          "prompt"=> "]#",
          "commands"=> [

          ],
          "tcp_port"=> 22,
          "password"=> "bogus"
        },
        "v4_addr"=> @mu_ip
      }
      # $log.level = Logger::DEBUG
      api = Mu::Command::Cmd_netconfig.new
      api.cmd_delete ["-e", "hosts/localhost"] # may not exist
      response = api.cmd_create ["-j", JSON(local_host), "-e", "hosts"]
      assert(response.include?("created"), "Failed to create host:" + response.to_s)
  end

end
