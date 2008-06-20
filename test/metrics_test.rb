$:.unshift(File.join(File.dirname(__FILE__), %w[.. lib]))
RAILS_ENV='test'
RAILS_ROOT=File.expand_path(File.join(File.dirname(__FILE__), '..'))
require 'rubygems'
require 'actionpack'
require 'action_controller'
require 'action_controller/test_process'
require 'active_record'

require 'metrics'
require File.dirname(__FILE__) + '/metrics_test_class'
require 'resolv'
require 'ipaddr'

class SomeClassToTest
  collect_metrics_on :my_method
  
  def my_method(blah = nil)
    print "blah = #{blah}\n" if blah != nil
    true
  end

  def my_non_metric_method(blah = nil)
    print "blah = #{blah}\n" if blah != nil
    true
  end
end

class SomeClassToTestWithoutCollection
  
  def my_method(blah = nil)
    print "blah = #{blah}\n" if blah != nil
    true
  end

  def my_non_metric_method(blah = nil)
    print "blah = #{blah}\n" if blah != nil
    true
  end
end

module SomeModuleToTest
  collect_metrics_on :the_method
  def the_method(blah)
    print "in the_method(#{blah})\n"
    true
  end
  
  def another_method(blah)
    print "in another_method(#{blah})\n"
    true
  end
end

class SomeClassToUseModuleMixin
  include SomeModuleToTest
  collect_metrics_on :another_method
end

class SomeController < ActionController::Base
  def index
    print "!!!!!!!!!!!!!! HERE\n"
    render :text => "hello world"
  end
end

class Test::SomeControllerThreshold < ActionController::Base
  def index
    print "!!!!!!!!!!!!!! HERE\n"
    render :text => "hello world"
  end
end

class Test::SomeControllerWithMetricsId < ActionController::Base
  def index
    Metrics.collect_metrics { print "!!!!!!!!!!!!!! HERE\n" }
    render :text => "hello world"
  end
end

class MockSocket < StringIO
  def readline; "HTTP 200 OK"; end
  def readuntil(a, b); ""; end
  def read_all(a); ""; end
end

class MetricsTest < Test::Unit::TestCase
  def setup
    ActiveRecord::Base.configurations = {'test' => {'adapter' => "sqlite3", "dbfile" => ":memory:"}}
    Metrics::Config[:min_real_time_threshold] = 0.0 # artifically lower the threshold so we catch everything for our tests
    start_logging()
  end
  
  def teardown
    stop_logging()
  end
  
  def test_http_metrics_log
    http = Net::HTTP.new("www.revolutionhealth.com", "80")
    http_output = MockSocket.new
    http_output.print "empty\nasdf\n\n"
    http_output.rewind
    http.instance_eval { @socket = http_output; @started = true }
    
    
    http.request_get("/test", { 'accept' => "text/plain"} )
    assert output.string =~ /.*Metrics.*Net::HTTP::Get.exec.*test/
    output.string.gsub!(/.*/, '')

    http.request_post("/test", "body", { 'accept' => "text/plain"} )
    assert output.string =~ /.*Metrics.*Net::HTTP::Post.exec.*test/
    output.string.gsub!(/.*/, '')


    http.send(:post, "/test", "body", { 'accept' => "text/plain"} )
    assert output.string =~ /.*Metrics.*Net::HTTP::Post.exec.*test/
    output.string.gsub!(/.*/, '')

  end

  def test_metrics_log_capture
    METRICS_LOGGER.error { "BLAH" }
    assert output.string =~ /.*BLAH\n/
  end
  
  def test_metrics_config
    default = Metrics::Config[:min_real_time_threshold]
    Metrics::Config[:min_real_time_threshold] = 0.5
    assert_equal 0.5, Metrics::Config[:min_real_time_threshold]
    assert_equal Metrics::Config[:min_real_time_threshold], Metrics::Config.instance.cfg[:min_real_time_threshold]
    Metrics::Config[:min_real_time_threshold] = default
    
    assert_equal "|", Metrics::Config[:log_delimiter]
  end
  
  def test_class_threshold    
    test_controller = Test::SomeControllerThreshold.new
    test_request = ActionController::TestRequest.new
    test_request.path = '/some'
    test_request.action = 'index'
    
    original_threshold = Metrics::Config[:min_real_time_threshold]
    Metrics::Config[:min_real_time_threshold] = 2.0 # adjust it
    begin
      response = test_controller.process_test(test_request)
    ensure
      Metrics::Config[:min_real_time_threshold] = original_threshold
    end
    
    assert_equal response.body, "hello world"
    assert_nil output.string =~ /\[Metrics\]/    
    output.string.gsub!(/.*/, '')
  end
  
  
  def test_metrics_id
    test_controller = Test::SomeControllerWithMetricsId.new
    test_request = ActionController::TestRequest.new
    test_request.path = '/some'
    test_request.action = 'index'
    response = test_controller.process_test(test_request)
    assert_equal response.body, "hello world"

    test1 = output.string.scan(/.*\[Metrics\]\|\[(\d*)\]/).flatten

    assert_equal 2, test1.size
    assert_equal test1[0], test1[1]


    output.string.gsub!(/.*/, '')
    test_controller = SomeController.new
    response = test_controller.process_test(test_request) 
    assert_equal response.body, "hello world"

    test2 = output.string.scan(/.*\[Metrics\]\|\[(\d*)\]/).flatten
    assert_equal 1, test2.size
    assert_not_nil test2[0]
    
    assert_not_equal test1[0], test2[0]
    
    output.string.gsub!(/.*/, '')    
  end
  

  def test_ar_enhanced_metrics
    assert output.string.empty?
    ActiveRecord::Base.establish_connection
    not_nil_checker = nil
    
    ActiveRecord::Base.connection.instance_eval <<-EOS
      log("select count(1);", "test") { not_nil_checker = true }
    EOS
    assert_equal false, output.string.empty?
    output.string.gsub!(/.*/, '')

    ActiveRecord::Base.connection.instance_eval <<-EOS
      log("select count(1);", "test")
    EOS
    assert_equal false, output.string.empty?

    assert_not_nil not_nil_checker
    output.string.gsub!(/.*/, '')

    ar_conf = ActiveRecord::Base.configurations['test'].merge({'host' => 'localhost.revolutionhealth.com', 
                                                               'username' => 'none', 'database' => 'test'})
    ar_conf.symbolize_keys!
    ActiveRecord::Base.connection.instance_eval { @config = ar_conf if @config.nil? }
    ActiveRecord::Base.connection.execute("select count(1);")
    
    print output.string + "\n\n"
    assert_equal false, output.string.blank?
    config = {'adapter' => "sqlite3", 
              'host' => 'localhost.revolutionhealth.com',
              'username' => 'none', 'database' => 'test'
             }
    config.symbolize_keys!
    
    host = config[:host].sub(/\..*/, '')
    assert_match /.*args\=\[\"#{config[:username]} #{host} #{config[:database]}\"\, \"select count\(1\)\;\"\].*/, output.string


    output.string.gsub!(/.*/, '')

    host_ip = nil
    Resolv.getaddresses(config[:host]).each { |x| host_ip = x if IPAddr.new(x).ipv4? }

    if host_ip != nil
      config[:host] = host_ip
      ActiveRecord::Base.connection.instance_variable_set("@config", config)
      ActiveRecord::Base.connection.execute("select count(1);")
  
      print output.string  
      print "\n\n"
      assert_equal false, output.string.blank?
      config = ActiveRecord::Base.connection.instance_variable_get("@config")

      host = config[:host].sub(/\..*/, '')
      host = config[:host] if not host.scan(/\d+/).empty?
      assert_match /.*args\=\[\"#{config[:username]} #{host} #{config[:database]}\"\, \"select count\(1\)\;\"\].*/, output.string
    end

    output.string.gsub!(/.*/, '')


    
    ActiveRecord::Base.connection.instance_eval <<-EOS
      def execute(sql, name = nil, retries = 2) #:nodoc:
        log(sql, name) { sleep(2) }
      rescue ActiveRecord::StatementInvalid => exception
        if exception.message.split(":").first =~ /Packets out of order/
          raise ActiveRecord::StatementInvalid, "'Packets out of order' error was received from the database. Please update your mysql bindings (gem install mysql) and read http://dev.mysql.com/doc/mysql/en/password-hashing.html for more information.  If you're on Windows, use the Instant Rails installer to get the updated mysql bindings."
        else
          raise
        end
      end
    EOS

    ActiveRecord::Base.connection.execute("SLEEP TEST")
    assert_equal false, output.string.empty?
  end

  def test_metrics_collection2
    tmp = RHG::MetricsTestClass.new.my_method("hi")
    assert_equal true, tmp
    assert SomeClassToTest.method_defined?(:__metrics_my_method__)

    test_obj = RHG::MetricsTestClass.new
    tmp2 = test_obj.my_method("hi")
    assert_equal true, tmp2
    assert SomeClassToTest.method_defined?(:__metrics_my_method__)
    
    tmp3 = test_obj.my_method("hi")
    assert_equal true, tmp3
    assert SomeClassToTest.method_defined?(:__metrics_my_method__)
  end

  def test_metrics_collection
    tmp = SomeClassToTest.new.my_method("hi")
    assert_equal true, tmp
    assert SomeClassToTest.method_defined?(:__metrics_my_method__)
  end
  
  def test_explicit_collection
    assert_equal "123", collect_result_test()
    assert_equal "321", collect_result_test(false)
  end
  
  def test_module_metrics
    tmp = Object.new.extend(SomeModuleToTest)
    result = tmp.the_method("here")
    assert_equal true, result
    assert SomeModuleToTest.method_defined?(:__metrics_the_method__)
    
    tmp2 = SomeClassToUseModuleMixin.new
    assert_equal true, tmp2.the_method("here")
    assert_equal true, tmp2.another_method("also")
    assert SomeClassToUseModuleMixin.method_defined?(:__metrics_the_method__)
    assert SomeClassToUseModuleMixin.method_defined?(:__metrics_another_method__)
    
  end
  
  def test_an_output
    some_class_instance = SomeClassToTest.new
    some_class_instance.my_method
    some_class_instance.my_method("HI")
    collect_result_test()
    collect_result_test2()
        
    METRICS_LOGGER.error("--------------- END TEST 1 -------------\n")
    
    Metrics::Config[:single_line_output] = true
    
    some_class_instance = SomeClassToTest.new
    some_class_instance.my_method
    some_class_instance.my_method("THAR")
    collect_result_test()
    collect_result_test2()
    
    test_controller = SomeController.new
    test_request = ActionController::TestRequest.new
    test_request.path = '/some'
    test_request.action = 'index'
    response = test_controller.process_test(test_request)
    #assert response.body == "hello world"
    METRICS_LOGGER.error("--------------- END TEST 2 -------------\n")

    
    print output.string  
    print "\n\n"
    assert_equal false, output.string.blank?
    
    output.string.gsub!(/.*/, '')
    
    old_level = METRICS_LOGGER.level
    METRICS_LOGGER.level = fatal_level
    collect_result_test2()
    assert_equal true, output.string.blank?
    
    METRICS_LOGGER.level = old_level
  end

  def test_empty_config
    orig_rails_env = Object.const_get('RAILS_ENV')
    Object.const_set('RAILS_ENV', 'staging')
    assert_nothing_raised { Metrics::Config.instance.send(:load_config) }
    Object.const_set('RAILS_ENV', orig_rails_env)
  end
  
  def test_benchmark
    
    Benchmark.bmbm do |x|
      x.report("new with metrics") do 
        SomeClassToTest.new
      end
      x.report("new without metrics") do 
        SomeClassToTestWithoutCollection.new
      end
      
      some_class_instance = SomeClassToTest.new
      x.report("method call with metrics") do 
        some_class_instance.my_method
      end
      x.report("method call without metrics") do 
        some_class_instance.my_non_metric_method
      end
      
      x.report("multiple method calls (1000) with metrics") do 
        1000.times { some_class_instance.my_method }
      end
      x.report("multiple method calls (1000) without metrics") do 
        1000.times { some_class_instance.my_non_metric_method }
      end
      
      x.report("args inspector") do 
        args_inspector("nothing")
      end
      
      x.report("random id 100") do
        100.times { rand(99999) }
      end

      x.report("random id 1") do
         rand(99999)
      end

    end
  end
  
  def test_no_logging
    disable_logging = lambda do
      Metrics.module_eval <<-EOS
        def log_metrics(result, args); end
      EOS
    end
    
    disable_logging.call()
    
    some_class_instance = SomeClassToTest.new
    Benchmark.bmbm do |x|
      x.report("multiple method calls with metrics and no logging") do 
        100.times { some_class_instance.my_method }
      end
      x.report("multiple method calls without metrics and no logging") do 
        100.times { some_class_instance.my_non_metric_method }
      end
    end
  end
  
  ITER_TIMES = 10000
  
  def test_logging_debug
    test_args = {:test => "to this", :another_key => "and this stuff"}
    default_level = METRICS_LOGGER.level
    METRICS_LOGGER.level = debug_level
    
    Benchmark.bmbm do |x|
      x.report("DEBUG MODE - test with debug on and in a block") do
        ITER_TIMES.times { METRICS_LOGGER.debug {"dm 1 - do something #{test_args.inspect}"} }
      end
      
      x.report("DEBUG MODE - test with debug on and a string") do
        ITER_TIMES.times { METRICS_LOGGER.debug "dm 2 - do something #{test_args.inspect}" } 
      end
      
      x.report("DEBUG MODE - test with debug on and a string and with if test") do
        ITER_TIMES.times { METRICS_LOGGER.debug "dm 3 - do something #{test_args.inspect}" if METRICS_LOGGER.debug? }
      end
    end
    
    METRICS_LOGGER.level = fatal_level
    
    Benchmark.bmbm do |x|
      x.report("FATAL MODE - test with debug on and in a block") do
        ITER_TIMES.times { METRICS_LOGGER.debug {"fm 1 - do something #{test_args.inspect}"} }
      end
      
      x.report("FATAL MODE - test with debug on and a string") do
        ITER_TIMES.times { METRICS_LOGGER.debug "fm 2 - do something #{test_args.inspect}" }
      end
      
      x.report("FATAL MODE - test with debug on and a string and with if test") do
        ITER_TIMES.times { METRICS_LOGGER.debug "fm 3 - do something #{test_args.inspect}" if METRICS_LOGGER.debug? }
      end
    end
    
    METRICS_LOGGER.level = default_level
  end
  
  
private

  def args_inspector(*args)
    args_str = args.inspect
  end
  
  def collect_result_test(testing_a = true)
    Metrics.collect_metrics("[acts_as_rhg_rateable] - associate_rating_template") do
      if (testing_a)
        "123"
      else
        "321"
      end
    end
  end
  
  def collect_result_test2(testing_a = true)
    Metrics.collect_metrics("[acts_as_rhg_rateable2] - associate_rating_template", testing_a, "something else") do
      if (testing_a)
        "123"
      else
        "321"
      end
    end
  end

  def fatal_level
    if defined?(Log4r)
      Log4r::FATAL
    else
      Logger::FATAL
    end
  end
  
  def debug_level
    if defined?(Log4r)
      Log4r::DEBUG
    else
      Logger::DEBUG
    end
  end
  
  
  def string_outputter
    @string_outputter
  end
  
  def output
    @output
  end
  
  def start_logging
    @output = StringIO.new
    if defined?(Log4r)
      @string_outputter = Log4r::IOOutputter.new("metrics_log", output)
      @string_outputter.formatter = METRICS_LOGGER.outputters[0].formatter
      METRICS_LOGGER.add(@string_outputter)
    else
      string_outputdev = Logger::LogDevice.new(@output, :shift_age => 0, :shift_size => 1048576)
      METRICS_LOGGER.instance_variable_set('@logdev', string_outputdev)
    end
    nowhere_log = Logger.new(StringIO.new)
    ActiveRecord::Base.logger =  nowhere_log # send AR logging off to no where
    ActionController::Base.logger =  nowhere_log # send AR logging off to no where
  end
  
  def stop_logging
    if defined?(Log4r)
      @string_outputter.close
      METRICS_LOGGER.remove(@string_outputter)
      @string_outputter = nil
      @output = nil
    end
  end
end

# CONFIDENTIAL AND PROPRIETARY. © 2007 Revolution Health Group LLC. All rights reserved.
# This source code may not be disclosed to others, used or reproduced without the written permission of Revolution Health Group.
