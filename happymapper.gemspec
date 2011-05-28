# encoding: UTF-8
require File.expand_path('../lib/happymapper/version', __FILE__)

Gem::Specification.new do |s|
  s.name         = 'happymapper'
  s.homepage     = 'May you have many happy mappings!'
  s.summary      = 'object to xml mapping library'
  s.homepage     = 'http://happymapper.rubyforge.org'
  s.rubyforge_project = 'happymapper'
  s.require_path = 'lib'
  s.authors      = ['John Nunemaker']
  s.email        = ['nunemaker@gmail.com']
  s.version      = HappyMapper::Version
  s.platform     = Gem::Platform::RUBY
  s.files        = Dir.glob("{examples,lib,spec}/**/*") + %w[License Rakefile README.rdoc]

  s.add_dependency              'libxml-ruby', '~> 2.0'
end