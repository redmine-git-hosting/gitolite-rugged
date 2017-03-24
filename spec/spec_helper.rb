require 'rubygems'
require 'simplecov'
require 'forgery'
require 'rspec'
require 'faker'
require 'support/helper'

## Configure SimpleCov
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::HTMLFormatter,
])

## Start Simplecov
SimpleCov.start do
  add_filter '/spec/'
  add_filter '/lib/core_ext'
end

## Configure RSpec
RSpec.configure do |config|
  include Helper

  config.color = true
  config.fail_fast = false
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

require 'gitolite'
require 'core_ext/faker/git'
require 'core_ext/faker/ssh'
