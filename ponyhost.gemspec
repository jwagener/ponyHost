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
  s.summary     = "Create and deploy Amazon S3 powered websites"
  s.description = <<-EOF
    ponyHost lets you to easily create Amazon S3 website buckets,
    push files to them and make them available under a *.ponyho.st or custom domain.
    A small HTTP server is also included.
  EOF
  
  s.required_rubygems_version = ">= 1.3.6"
  s.add_dependency 'aws-s3'
  
  s.license      = "MIT"
  s.files        = Dir.glob("{lib}/**/*") + %w(README.md bin/ponyhost)
  s.require_path = 'lib'
  s.executables  = ['ponyhost']
end
