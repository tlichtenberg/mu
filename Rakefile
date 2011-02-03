require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "mu"
  gem.homepage = "http://github.com/pcapr/mu"
  gem.license = "MIT"
  gem.summary = "general purpose mu gem"
  gem.description = "general purpose mu gem"
  gem.email = "lichtenberg.tom@gmail.com"
  gem.authors = ["pcapr"]
  gem.executables = ['mu']
  gem.files = ['lib/**/*.rb','test/data/*', 'rdoc/**/*'].to_a
  # Include your dependencies below. Runtime dependencies are required when using your gem,
  # and development dependencies are only needed for development (ie running rake tasks, tests, etc)
  gem.add_dependency 'nokogiri', ' >= 1.4.4'
  gem.add_dependency 'rest-client', ' >= 1.6.1'
  gem.add_dependency 'mime-types', ' >= 1.16'
  gem.add_dependency 'json_pure', ' >= 1.4.6'
  gem.add_dependency 'hexy', ' >= 0.1.1'
end
Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib'
  test.libs << 'test'
  test.libs << '/usr/local/lib/ruby'
  test.pattern = 'test/tc_test_*.rb'
  test.verbose = true
end

require 'rcov/rcovtask'
Rcov::RcovTask.new do |test|
 # test.rcov_opts << "--exclude \"test/*,gems/*,/Library/Ruby/*,config/*\" --rails"
  test.libs << 'lib'
  test.libs << 'lib/mu/api' 
  test.libs << 'lib/mu/command'
  test.libs << 'test'
  test.pattern = './test/tc_test_*.rb'
  test.verbose = true
end

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "mu #{version}"
  rdoc.options << '--all'
  rdoc.rdoc_files.include('doc/*')
end
