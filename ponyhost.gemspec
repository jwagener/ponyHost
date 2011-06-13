# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'ponyhost'

Gem::Specification.new do |s|
  s.name        = "ponyhost"
  s.rubyforge_project = "ponyhost"
  s.version     = PonyHost::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Johannes Wagener"]
  s.email       = ["johannes@wagener.cc"]
  s.homepage    = "http://ponyho.st"
  s.summary     = "Create super simple S3 powered websites"
  s.description = "ponyHost allows you to easily create S3 website buckets with a nice hostname and push files to it"

  s.required_rubygems_version = ">= 1.3.6"

  s.add_dependency 'aws-s3'
  #s.add_development_dependency "fakeweb"

  s.files        = Dir.glob("{lib}/**/*") + %w(README.md bin/ponyhost)
  s.require_path = 'lib'
  s.executables = ['ponyhost']
end
