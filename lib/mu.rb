require 'rubygems'
require 'hexy'
require 'json/pure'
require 'logger'
require 'net/https'
require 'nokogiri'
require 'restclient'
require 'uri'

class Mu
    require 'mu/helper'
    @version = "5.7.2"
    Version = @version.freeze
    $log = Logger.new(STDOUT)
    $cookie = nil # http_helper
           
    extend Mu::Helper
    
    def self.run cmd, argv     
        $log.datetime_format = "%Y-%m-%d %H:%M:%S"
        $log.level = Logger::INFO
        $log.formatter = proc { |severity, datetime, progname, msg|
         "[#{datetime} #{severity}]: #{msg}\n"
         }

        check_version

        kname, mname = cmd.split(':', 2)
        klass = Mu::Command.const_get kname.capitalize rescue nil
        mname ||= 'default'
        mname = "cmd_#{mname}".to_sym
        if klass and klass < Mu::Command and klass.method_defined? mname
            command = klass.new
            begin
                command.send mname, argv
            rescue => e
                error e.message.chomp('.')
            end
        else
            error "Unknown command #{cmd}"
        end        
    end

    def self.check_version
        system = Mu::System.new(ENV['MU_IP'], ENV['MU_ADMIN_USER'], ENV['MU_ADMIN_PASS'])
        response = Nokogiri::XML(system.status)
        version_string = response.xpath("//versions/platform")[0].content
        #puts "version = #{version_string}"
        idx = version_string.rindex(".")
        version = version_string[0...idx]
        #puts "version = #{version}"
        #puts "@version = #{@version}"
        if @version > version
          puts "*** Warning, version mismatch. The Mu Gem version (#{@version}) is higher than the Mu System version (#{version}) ***"
        end
    end
end

require 'mu/client'
require 'mu/curl/error'
require 'mu/curl/verify'
require 'mu/command'
require 'mu/http_helper'
