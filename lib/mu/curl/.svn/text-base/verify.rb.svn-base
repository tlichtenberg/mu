class Mu
module Curl 
class Verify
    class Request
        def self.parse data
            ios = StringIO.new data.unpack('m')[0]
            rqrs = { :line => '', :headers => [], :content => '' }
            while true
                line = ios.readline
                break if not line or line == "\r\n"
                if rqrs[:line].empty?
                    rqrs[:line] = line.chomp
                else
                    if /^([^:]+):(.*)/ =~ line
                        key = $1
                        val = $2.strip
                        rqrs[:headers] << { :line => line.chomp, :key => key, :val => val }
                    end
                end
            end

            rqrs[:content] = ios.read
            return rqrs
        end
        
        attr_reader :line
        attr_reader :method
        attr_reader :url
        attr_reader :headers
        attr_reader :content
        
        def initialize json
            rq = Request.parse json['bytes'][0]['data']
            @line = rq[:line]
            @method, @url, _ = rq[:line].split(/\s+/, 3)
            @content = rq[:content]
            @headers = Hash.new
            rq[:headers].each { |h| @headers[h[:key]] = h[:val] }
        end
    end
    
    class Response
        attr_reader :line
        attr_reader :status
        attr_reader :message
        attr_reader :headers
        attr_reader :content
        
        def initialize json
            rs = Request.parse json['bytes'][1]['data']
            @line = rs[:line]
            _, @status, @message = rs[:line].split(/\s+/, 3)
            @status = @status.to_i
            @content = rs[:content]
            @headers = Hash.new
            rs[:headers].each { |h| @headers[h[:key]] = h[:val] }
        end        
    end
    
    class Result
        attr_reader :region
        attr_reader :duration
        attr_reader :connect
        attr_reader :request
        attr_reader :response
        
        def initialize json
            result = json['result']
            stats = result['statistics']
            
            @region = json['region']
            @duration = stats['duration']['avg']
            @connect = stats['steps'][0]['duration']['avg']
            @request = Request.new result
            @response = Response.new result
        end        
    end
    
    def self.execute args
        args.delete 'pattern'

        res = Command::API.client.curl args
        if res['error']
            if res['error'] == 'authorize'
                raise Error::Authorize.new(res)
            else
                raise Error.new(res)
            end
        end

        return self.new(res['job_id'])
    end
    
    attr_reader :job_id
    
    def initialize job_id
        @job_id = job_id
    end
    
    def result
        while true
            sleep 2.0

            job = Command::API.client.job_status job_id
            if job['error']
                raise Error
            end

            result = job['result']
            next if job['status'] == 'queued'
            next if job['status'] == 'running' and not result

            if result['error']
                result['region'] = job['region']
                if result['dns']
                    raise Error::DNS.new(result)
                elsif result['step'] == 0
                    raise Error::Connect.new(result)
                elsif result['step'] == 2
                    raise Error::Timeout.new(result)
                elsif result['assert'] == 0
                    raise Error::Status.new(result)
                else
                    raise Error
                end
            end
            
            return Result.new(job)
        end
    end
    
    def abort
        Command::API.client.abort_job job_id rescue nil
    end    
end
end # Curl
end # Mu
