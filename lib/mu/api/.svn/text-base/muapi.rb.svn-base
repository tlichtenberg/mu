class Mu
class Muapi
  include Helper
  
  attr_accessor :host, :docroot, :posted_uuid, :run_uuid, :job_id, :username, :password, :params, :expected_error

  def initialize(host=ENV['MU_IP'], username=ENV['MU_ADMIN_USER'], password=ENV['MU_ADMIN_PASS'])
    @host = host
    @username  = username
    @password  = password
    @docroot = "/api/v3/"
    @params = nil
    @expected_error = nil
    @http = HttpHelper.new(@host, @username, @password, @docroot)
    msg "Created Mu Api object to :#{@host}", Logger::DEBUG
  end

  # lists the statuses of tests
  #  * status = the status type, such as 'running' or 'failed'
  def list_by_status(status="")
    uuid_list = Array.new()
    if !status.empty?
      doc = @http.get_xml("analysis/list?status=#{status}")
    else
      doc = @http.get_xml("analysis/list")
    end
    unless doc.xpath("//analysis").empty?
      doc.xpath('//analysis').each { |e| uuid_list << e.attribute('uuid') }
    end
    return uuid_list
  end

  # returns the status of a test
  #  * uuid = the uuid of the test
  def status(uuid=@run_uuid)
    doc = @http.get_xml("analysis/status?uuid=#{uuid}")
    return nil if doc.nil?
    unless doc.xpath("//analysis").empty?
      status = doc.xpath("//status")[0].text
      return status
    end
    return doc
  end

  # starts a test
  #  * uuid = the uuid of the test
  def run(uuid, rename="")
    req = "analysis/run?uuid=#{uuid}"
    unless rename.empty?
      req = "#{req}&rename=#{rename}"
    end
    doc = @http.get_xml(req)
    unless doc.xpath("//analysis").empty?
      @run_uuid = doc.xpath("//analysis")[0].attribute('uuid')
      return @run_uuid
    end
    return @run_uuid
  end

  # stops a running test
  #  * uuid = the uuid of the test
  def stop(uuid=@run_uuid)
    doc = @http.get_xml("analysis/stop?uuid=#{uuid}")
    unless doc.xpath("//analysis").empty?
      status = doc.xpath("//analysis")[0].attribute('status')
      return status
    end
    return false
  end

  # pauses a running test
  #  * uuid = the uuid of the test
  def pause(uuid=@run_uuid)
    doc = @http.get_xml("analysis/pause?uuid=#{uuid}")
    unless doc.xpath("//analysis").empty?
      status = doc.xpath("//analysis")[0].attribute('status')
      return status
    end
    return false
  end

  # resumes a suspended test
  #  * uuid = the uuid of the test
  def resume(uuid=@run_uuid)
    doc = @http.get_xml("analysis/resume?uuid=#{uuid}")
    unless doc.xpath("//analysis").empty?
      status = doc.xpath("//analysis")[0].attribute('status')
      return status
    end
    return false
  end

  # deletes the specified test
  #  * uuid = the uuid of the test
  def delete(uuid=@run_uuid)
    doc = @http.get_xml("analysis/delete?uuid=#{uuid}")
    unless doc.xpath("//analysis").empty?
      status = doc.xpath("//analysis")[0].attribute('status')
      return status
    end
    return true
  end

  # returns a list of faults from the specified test
  #  * uuid = the uuid of the test
  def get_faults(uuid=@run_uuid)
    doc = @http.get_xml("templates/export?uuid=#{uuid}")
    unless doc.xpath("//analysis").empty?
      faults = get_xml("analysis/getFaultList?uuid=#{uuid}",true)
      return faults
    end
    return "error: no analysis with uuid: #{uuid} found"
  end

  # returns the name of an test
  #   * uuid = the uuid of the test
  def get_name(uuid=@run_uuid)
    doc = @http.get_xml("templates/export?uuid=#{uuid}")
    unless doc.xpath("//analysis").empty?
      return doc.xpath("//analysis")[0].attribute('name')
    end
    return
  end

  # lists the templates on the Mu system using the template type and template name:
  #  * type = the template type
  def list(type)
    names = Array.new
    doc = @http.get_xml("templates/list?type=#{type}")
    doc.xpath("//templates/*").each {|a| names << a.attribute('name') }
    return names
  end

  # lists the types of templates on the Mu system
  def types
    doc = @http.get("templates/types?")
    return doc
  end

  # exports a template from the Mu system using the template type and template name
  #  * name = the template name
  def export_by_type_and_name(type, name)
    return @http.get_xml("templates/export?type=#{type}&name=#{name}")
  end

  # exports a template from the Mu system using the template uuid
  #  * uuid = the template uuid
  def export_by_uuid(uuid)
    return @http.get_xml("templates/export?uuid=#{uuid}")
  end

  # performs archive operations
  #   * command=run to create a test archive
  #   * command=status to view the status of a test archive job
  #   * command=get to download a test archive job
  #   * uuid = the uuid of the test
  def archive(command="run", id=@run_uuid)
    case command
    when 'run'
      request_string = "archive/run?uuid=#{id}"
      request_string += @params unless @params.nil?
      doc = @http.get_xml(request_string)
      unless doc.xpath("//job").empty?
        @job_id = doc.xpath("//job")[0].attribute('id')
        msg "job_id = #{@job_id}"
        return @job_id
      end
      return doc
    when 'status'
      doc = @http.get("archive/status?jobId=#{id}")
      return doc
    when 'get'
      file_size = @http.download_file("archive/get?jobId=#{id}","#{id}.zip")
      return "#{id}.zip file size = #{file_size}"
    end
    return false
  end

  # performs backup operations
  #  * command=run to create a system backup file.
  #  * command=status to view the status of a backup job. If no backup job is running, gets the date of the most recent backup.
  #  * command=get to retrieve the backup file
  #  * name = backup file name
  def backup(command="run", name="")
    case command
    when 'run'
      doc = @http.get_xml("backup/run")
      unless doc.xpath("//job").empty?
        @job_id = doc.xpath("//job")[0].attribute('id')
        msg "job_id = #{@job_id}"
        return @job_id
      end
      return doc
    when 'status'
      doc = @http.get("backup/status")
      return doc
    when 'get'
      file_size = @http.download_file("backup/get","#{name}.dat")
      return "#{name}.dat file size = #{file_size}"
    end
    return false
  end

  # packet capture operations
  #   * command=run to start capturing packets on the specified Mu appliance port
  #   * command=status tp view the status of packet capture activity
  #   * command=get to download the pcap file generated during packet capture
  #   * port = the Mu appliance port
  #   * id = job_id for status and get commands
  def capture(command='run', port='a1', id=@job_id)
    case command
    when 'run'
      doc = @http.get_xml("capture/run?port=#{port}")
      unless doc.xpath("//job").empty?
        @job_id = doc.xpath("//job")[0].attribute('id')
        msg "job_id = #{@job_id}"
        return @job_id
      end
      return doc
    when 'status'
      doc = @http.get("capture/status?jobId=#{id}")
      return doc
    when 'get'
      file_size = @http.download_file("capture/get?jobId=#{id}","#{id}.pcap")
      return "#{id}.pcap file size = #{file_size}"
    end
    return false
  end

end 
end # Mu
