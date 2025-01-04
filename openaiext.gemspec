Gem::Specification.new do |s|
  s.name          = 'openaiext'
  s.version       = '0.0.9'
  s.date          = '2024-12-28'
  s.platform      = Gem::Platform::RUBY
  s.summary       = 'Ruby OpenAI Extended'
  s.description   = 'Based on ruby-openai, adds some extra features'
  s.authors       = ['Gedean Dias']
  s.email         = 'gedean.dias@gmail.com'
  s.files         = Dir['README.md', 'lib/**/*']
  s.require_paths = ['lib']
  s.required_ruby_version = '>= 3'
  s.homepage      = 'https://github.com/gedean/openaiext'
  s.license       = 'MIT'
  s.add_dependency 'ruby-openai', '~> 7'
  s.add_dependency 'oj', '~> 3'
  # s.post_install_message = %q{Please check readme file for use instructions.}
end
