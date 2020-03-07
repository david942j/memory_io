# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'date'

require 'memory_io/version'

Gem::Specification.new do |s|
  s.name          = 'memory_io'
  s.version       = ::MemoryIO::VERSION
  s.date          = Date.today.to_s
  s.summary       = 'memory_io'
  s.description   = <<-EOS
Read/Write complicated structures in memory easily.
  EOS
  s.license       = 'MIT'
  s.authors       = ['david942j']
  s.email         = ['david942j@gmail.com']
  s.files         = Dir['lib/**/*.rb'] + %w(README.md)
  s.homepage      = 'https://github.com/david942j/memory_io'

  s.required_ruby_version = '>= 2.3'

  s.add_runtime_dependency 'dentaku', '>= 2.0.11'

  s.add_development_dependency 'rake', '~> 13.0'
  s.add_development_dependency 'rspec', '~> 3.5'
  s.add_development_dependency 'rubocop', '~> 0.59'
  s.add_development_dependency 'simplecov', '~> 0.17'
  s.add_development_dependency 'yard', '~> 0.9'
end
