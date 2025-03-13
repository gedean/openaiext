require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new

task default: [:spec, :rubocop]

desc 'Run the test suite'
task :test do
  Rake::Task['spec'].invoke
end

namespace :doc do
  require 'yard'
  YARD::Rake::YardocTask.new do |task|
    task.files   = ['lib/**/*.rb']
    task.options = ['--markup', 'markdown']
  end
end

desc 'Generate documentation'
task :doc do
  Rake::Task['doc:yard'].invoke
end

desc 'Run console with the gem loaded'
task :console do
  require 'irb'
  require 'irb/completion'
  require 'openaiext'
  ARGV.clear
  IRB.start
end