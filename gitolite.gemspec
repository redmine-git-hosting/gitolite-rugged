# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.push(lib) unless $LOAD_PATH.include?(lib)
require 'gitolite/version'

Gem::Specification.new do |s|
  s.name        = 'gitolite-rugged'
  s.version     = Gitolite::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Oliver Günther']
  s.email       = ['mail@oliverguenther.de']
  s.homepage    = 'https://github.com/oliverguenther/gitolite-rugged'
  s.summary     = %q{A Ruby gem for manipulating the Gitolite Git backend via the gitolite-admin repository.}
  s.description = %q{This gem is designed to provide a Ruby interface to the Gitolite Git backend system using libgit2/rugged. This gem aims to provide all management functionality that is available via the gitolite-admin repository (like SSH keys, repository permissions, etc)}
  s.license     = 'MIT'

  s.add_runtime_dependency 'rugged',  '~> 0.22',  '>= 0.22.2'
  s.add_runtime_dependency 'gratr19', '~> 0.4.4', '>= 0.4.4.1'

  s.add_development_dependency 'rake',      '~> 10.4', '>= 10.4.2'
  s.add_development_dependency 'rspec',     '~> 3.3',  '>= 3.3.0'
  s.add_development_dependency 'forgery',   '~> 0.6',  '>= 0.6.0'
  s.add_development_dependency 'simplecov', '~> 0.10', '>= 0.10.0'
  s.add_development_dependency 'faker',     '~> 1.5',  '>= 1.5.0'
  s.add_development_dependency 'sshkey',    '~> 1.7',  '>= 1.7.0'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']
end
