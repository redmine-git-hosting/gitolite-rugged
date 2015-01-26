# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "gitolite/version"

Gem::Specification.new do |s|
  s.name        = "gitolite-rugged"
  s.version     = Gitolite::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Oliver Günther"]
  s.email       = ["mail@oliverguenther.de"]
  s.homepage    = "https://github.com/oliverguenther/gitolite-rugged"
  s.summary     = %q{A Ruby gem for manipulating the Gitolite Git backend via the gitolite-admin repository.}
  s.description = %q{This gem is designed to provide a Ruby interface to the Gitolite Git backend system using libgit2/rugged. This gem aims to provide all management functionality that is available via the gitolite-admin repository (like SSH keys, repository permissions, etc)}
  s.license     = 'MIT'

  s.add_development_dependency 'rake',           '~> 10.4', '>= 10.4.2'
  s.add_development_dependency 'rdoc',           '~> 4.1', '>= 4.1.1'
  s.add_development_dependency 'rspec',          '~> 3.1', '>= 3.1.0'
  s.add_development_dependency 'forgery',        '~> 0.6', '>= 0.6.0'
  s.add_development_dependency 'simplecov',      '~> 0.8', '>= 0.8.2'
  s.add_development_dependency 'simplecov-rcov', '~> 0.2', '>= 0.2.3'
  s.add_development_dependency 'spork',          '~> 0.9', '>= 0.9.2'

  s.add_dependency 'rugged',  '~> 0.21', '>= 0.21.4'
  s.add_dependency 'gratr19', '~> 0.4.4', '>= 0.4.4.1'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
