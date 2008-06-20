require 'rubygems'
require 'rake/gempackagetask'
require 'test/unit'

desc 'Default Task'
task :default => [:test, :package]

spec = eval(File.read("metrics.gemspec"))

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end

task :install => [:package] do
  sh %{sudo gem install pkg/#{spec.name}-#{spec.version}}
end

task :test do
  runner = Test::Unit::AutoRunner.new(true)
  runner.to_run << 'test'
  runner.pattern =  [/_test.rb$/]
  exit if !runner.run
end
