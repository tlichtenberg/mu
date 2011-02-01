class Mu
class Client
    attr_reader :mu
    
    def initialize user, apik, host='escale.mudynamics.com'
        scheme = host.index('localhost') ? 'http' : 'https'
        @mu = RestClient::Resource.new "#{scheme}://#{host}", \
            :headers => {
                :x_api_user => user,
                :x_api_key => apik,
                :x_api_version => ::Mu::Version
            }
    end
    
    def curl data
        JSON.parse mu['/api/1/curl'].post(data.to_json)
    end
    
    def login
        JSON.parse mu['/account/login/api'].get
    end
    
    def job_status job_id
        JSON.parse mu["/api/1/jobs/#{job_id}/status"].get
    end
    
    def abort_job job_id
        JSON.parse mu["/api/1/jobs/#{job_id}/abort"].put('')
    end
end
end
