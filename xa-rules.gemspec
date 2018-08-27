# coding: utf-8
Gem::Specification.new do |s|  
  s.name        = 'xa-rules'
  s.version     = '0.3.0'
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Don Kelly"]
  s.email       = ["karfai@gmail.com"]
  s.summary     = "XA Rules"
  s.description = "Shared rule gem"

  s.add_dependency 'parslet'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'faker'
  s.add_development_dependency 'fuubar'
  
  s.files        = Dir.glob("{bin,lib}/**/*")
  s.require_path = 'lib'
end  
