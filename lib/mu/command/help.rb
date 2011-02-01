class Mu
class Command
class Help < Command
    def cmd_default argv
        puts
        puts "Usage: mu <command>:<option>"
        helps = [
            { :cmd => 'mu help', :help => "Display this help" },
            { :cmd => 'mu cmd_appid:help', :help => 'Show help on using the appid application for running multi-host msl files at scale'},
            { :cmd => 'mu cmd_cli:help', :help => 'Show help on using the Mu CLI Api through the command-line' },
            { :cmd => 'mu cmd_ddt:help', :help => 'Show help on using the Studio Verify Api through the command-line' },
            { :cmd => 'mu cmd_homepage:help', :help => 'Show help on using the Homepage Api through the command-line' },
            { :cmd => 'mu cmd_muapi:help', :help => 'Show help on using the Mu Api for fuzzing, templates, backup and archive' },
            { :cmd => 'mu cmd_netconfig:help', :help => 'Show help on using the Netconfig Api through the command-line'},
            { :cmd => 'mu cmd_runscale:help', :help => 'Show help on running the Studio Scale app'},
            { :cmd => 'mu cmd_runscenario:help', :help => 'Show help on running the Scenario Editor Verify app' },
            { :cmd => 'mu cmd_runverify:help', :help => 'Show help on running the Studio Verify app' },
            { :cmd => 'mu cmd_scale:help', :help => 'Show help on using the Scale Api through the command-line' },
            { :cmd => 'mu cmd_system:help', :help => 'Show help on using the System Api through the command-line' },
        ]
        max_cmd_size = helps.inject(0) { |memo, obj| [ obj[:cmd].size, memo ].max } + 4
        helps.each do |h|
            puts "%*s - %s" % [max_cmd_size, h[:cmd], h[:help]]
        end
        puts
    end
end
end # Command
end # Mu
