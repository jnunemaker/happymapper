require 'rubygems'
require 'bundler/setup'

require 'rspec'
require File.expand_path('../../lib/happymapper', __FILE__)

RSpec.configure do |c|
  c.raise_errors_for_deprecations!
end

def fixture_file(filename)
  File.read(File.dirname(__FILE__) + "/fixtures/#{filename}")
end
