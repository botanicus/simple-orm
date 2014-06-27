#!/usr/bin/env gem build

Gem::Specification.new do |s|
  s.name              = 'simple-orm'
  s.version           = '0.0.1'
  s.date              = Date.today.to_s
  s.authors           = ['https://github.com/botanicus']
  s.summary           = 'Does what is says on the can. Nothing more, nothing less.'
  s.description       = 'A simple ORM. By default it stores to Redis hashes.'
  s.email             = 'james@101ideas.cz'
  s.homepage          = 'https://github.com/botanicus/simple-orm'
  s.rubyforge_project = s.name
  s.license           = 'MIT'

  s.files             = ['README.md', *Dir.glob('**/*.rb')]

  s.add_runtime_dependency('redis', '~> 3')
  s.add_runtime_dependency('hiredis', '~> 0')
end
