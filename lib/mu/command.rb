#require 'test/unit/assertions'

# The default template string contains what was sent and received. Strip 
# these out since we don't need them
=begin
class Test::Unit::Assertions::AssertionMessage
    alias :old_template :template
    
    def template
        @template_string = ''
        @parameters = []
        old_template
    end
end
=end

class Mu
class Command
    #include Test::Unit::Assertions
    include Helper

    @@mu_ip = ENV['MU_IP']
    @@mu_admin_user = ENV['MU_ADMIN_USER']
    @@mu_admin_pass = ENV['MU_ADMIN_PASS']
end
end # Mu

Dir["#{File.dirname(__FILE__)}/command/*.rb"].each { |c| require c }
