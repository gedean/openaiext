Gem::Specification.new do |s|
  s.name          = 'openaiext'
  s.version       = '0.0.12'
  s.date          = '2025-01-10'
  s.platform      = Gem::Platform::RUBY
  s.summary       = 'Ruby OpenAI Extended'
  s.description   = 'Based on ruby-openai, adds some extra features for working with OpenAI APIs'
  s.authors       = ['Gedean Dias']
  s.email         = 'gedean.dias@gmail.com'
  s.files         = Dir['README.md', 'LICENSE', 'CHANGELOG.md', 'lib/**/*']
  s.require_paths = ['lib']
  s.required_ruby_version = '>= 3'
  s.homepage      = 'https://github.com/gedean/openaiext'
  s.license       = 'MIT'
  
  # Runtime dependencies
  s.add_dependency 'ruby-openai', '~> 8'
  s.add_dependency 'oj', '~> 3'
  
  # Development dependencies
  s.add_development_dependency 'rspec', '~> 3'
  s.add_development_dependency 'webmock', '~> 3'
  s.add_development_dependency 'rubocop', '~> 1'
  s.add_development_dependency 'simplecov', '~> 0.22'
  s.add_development_dependency 'yard', '~> 0.9'
end