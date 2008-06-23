Gem::Specification.new do |s|
  s.name = %q{metrics}
  s.version = "0.0.9"

  s.specification_version = 2 if s.respond_to? :specification_version=

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Revolution Health"]
  s.autorequire = %q{metrics}
  s.date = %q{2008-06-23}
  s.description = %q{metrics allows one to track the performance of particular controllers, database calls, and other methods}
  s.email = %q{rails-trunk@revolutionhealth.com}
  s.extra_rdoc_files = ["README", "LICENSE", "TODO"]
  s.files = ["LICENSE", "README", "Rakefile", "TODO", "lib/metrics", "lib/metrics/collector.rb", "lib/metrics/config.rb", "lib/metrics/logger.rb", "lib/metrics.rb", "lib/rails", "lib/rails/activerecord_enhanced_metrics.rb", "lib/rails/activerecord_metrics.rb", "lib/rails/controller_metrics.rb", "lib/ruby", "lib/ruby/http_metrics.rb", "lib/ruby/metric_extensions.rb", "test/metrics_test.rb", "test/metrics_test_class.rb", "init.rb"]
  s.homepage = %q{http://github.com/revolutionhealth/metrics}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.1.1}
  s.summary = %q{metrics allows one to track the performance of particular controllers, database calls, and other methods}
end
