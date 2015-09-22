require 'bundler'
Bundler::GemHelper.install_tasks

require 'rake'
require 'rspec/core/rake_task'
require 'rdoc/task'

## RDoc Task
Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "Gitolite #{Gitolite::VERSION}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end


## Other Tasks
desc 'Open an irb session preloaded with this library'
task :console do
  sh "irb -rubygems -r ./lib/gitolite.rb"
end


desc 'Start unit tests'
task test: :default

task :default do
  RSpec::Core::RakeTask.new(:spec) do |config|
    config.rspec_opts = '--color'
  end
  Rake::Task['spec'].invoke
end
