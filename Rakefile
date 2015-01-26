require 'bundler'
Bundler::GemHelper.install_tasks

require 'rake'
require 'rspec/core/rake_task'
require 'rdoc/task'


## Helper Functions
def name
  @name ||= Dir['*.gemspec'].first.split('.').first
end


def version
  line = File.read("lib/#{name}/version.rb")[/^\s*VERSION\s*=\s*.*/]
  line.match(/.*VERSION\s*=\s*['"](.*)['"]/)[1]
end


## RDoc Task
Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "#{name} #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end


## Other Tasks
desc "Open an irb session preloaded with this library"
task :console do
  sh "irb -rubygems -r ./lib/#{name}.rb"
end


desc "Show library version"
task :version do
  puts "#{name} #{version}"
end


desc "Start unit tests"
task :test => :default
task :default do
  RSpec::Core::RakeTask.new(:spec) do |config|
    config.rspec_opts = "--color --format doc --fail-fast"
  end
  Rake::Task["spec"].invoke
end
