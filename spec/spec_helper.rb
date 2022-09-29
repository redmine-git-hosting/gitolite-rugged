require 'simplecov'
require 'forgery'
require 'rspec'
require 'faker'
require 'support/helper'

## Start Simplecov
SimpleCov.start do
  add_filter 'spec/'
end

## Configure RSpec
RSpec.configure do |config|
  include Helper

  config.color = true
  config.fail_fast = false

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # disable monkey patching
  # see: https://relishapp.com/rspec/rspec-core/v/3-8/docs/configuration/zero-monkey-patching-mode
  config.disable_monkey_patching!
end

require 'gitolite'
require 'core_ext/faker/git'
require 'core_ext/faker/ssh'
