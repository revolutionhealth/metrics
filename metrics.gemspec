Gem::Specification.new do |s|
  s.name = "metrics"
  s.version = "0.0.9"
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = false
  s.extra_rdoc_files = ["README", "LICENSE", 'TODO']
  s.summary = "metrics allows one to track the performance of particular controllers, database calls, and other methods"
  s.description = s.summary
  s.author = "RHG Team"
  s.email = "rails-trunk@revolutionhealth.com"
  s.homepage = "http://revolutiononrails.blogspot.com"

  # Uncomment this to add a dependency
  # s.add_dependency "foo"

  s.require_path = 'lib'
  s.autorequire = s.name
  s.files = %w(LICENSE README Rakefile TODO) + FileList["lib/**/*"].to_a + ['init.rb'] + FileList["config/**/*"].to_a + FileList["test/**/*"].to_a
end
