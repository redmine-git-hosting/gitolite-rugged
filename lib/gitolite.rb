require 'tempfile'
require 'fileutils'
require 'pathname'

require 'rugged'
require 'gratr'

require 'zeitwerk'
loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect 'ssh_key' => 'SSHKey'
loader.setup

module Gitolite
end
