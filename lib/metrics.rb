# CONFIDENTIAL AND PROPRIETARY. © 2007 Revolution Health Group LLC. All rights reserved.
require 'metrics/config'
require 'metrics/collector'
require 'benchmark'

if not defined?(METRICS_LOGGER)
  if defined?(RAILS_DEFAULT_LOGGER)  
    METRICS_LOGGER = RAILS_DEFAULT_LOGGER 
    METRICS_LOGGER.warn("METRICS_LOGGER is using RAILS_DEFAULT_LOGGER") if METRICS_LOGGER.warn?
  else
    require 'logger'
    METRICS_LOGGER = Logger.new(STDOUT)
  end
end
require 'metrics/logger'

module Metrics
  extend self
    
  def collect_metrics(label = nil, *args)
    reset_metrics_id = false
    collector = nil
    if Metrics::Logger.enabled?
      @@_metrics_id ||= nil
      if @@_metrics_id.nil?
        reset_metrics_id = true
        @@_metrics_id = rand(99999)
      end
      collector = Metrics::Collector.new
      collector.begin_metric()
    end
    
    result = yield

    log_metrics(collector.end_metric(label || metric_label), args) if Metrics::Logger.enabled?
    @@_metrics_id = nil if reset_metrics_id
    result
  end

  protected
  def disable_metrics(disable = true)
    if disable && !respond_to?(:orig_begin_metric)
      alias :orig_end_metric :end_metric
      alias :end_metric :disabled_metric
      alias :orig_begin_metric :begin_metric
      alias :begin_metric :disabled_metric
    elsif !disable && respond_to?(:orig_begin_metric)
      alias :end_metric :orig_end_metric
      alias :begin_metric :orig_begin_metric 
    end
  end
  
  private
  def begin_metric()
    if Metrics::Logger.enabled?
      @@_metrics_id = rand(99999)
      @collector = Metrics::Collector.new
      @collector.begin_metric() if @collector != nil
    end
  end
  
  def end_metric()
    if Metrics::Logger.enabled? and @collector != nil
      result = @collector.end_metric(metric_label) 
      log_metrics(result)
    end
  end
    
  
  METRICS_CAPTION = Benchmark::Tms::CAPTION.delete("\n")
  METRICS_FMTSTR = "%10.6r"
  METRICS_LABEL = "[Metrics]"
  
  def log_metrics(result, *args)
    threshold = Metrics::Config[self.class.name.underscore.to_sym] rescue Metrics::Config[:min_real_time_threshold]
    threshold ||= Metrics::Config[:min_real_time_threshold]

    if result != nil && (result.real > threshold)
      if Metrics::Config[:single_line_output]
        delimiter = Metrics::Config[:log_delimiter]
        output = METRICS_LABEL
        output += delimiter + "[#{@@_metrics_id}]" if Metrics::Config[:metrics_tracking_id]
        output += delimiter + "[#{result.label}]"
        output += delimiter + real_time(result).strip
        output += delimiter + controller_args if respond_to?(:controller_name)
        output += delimiter + "args=#{args[0].inspect}" if (args != nil) and (args.size > 0)
        Metrics::Logger.log(output)
      else
        Metrics::Logger.log("#{METRICS_LABEL} #{result.label}")
        Metrics::Logger.log("#{METRICS_LABEL} Metrics Id=#{@@_metrics_id}") if Metrics::Config[:metrics_tracking_id]
        Metrics::Logger.log("#{METRICS_LABEL} args=#{args[0].inspect}") if (args != nil) and (args.size > 0)
        Metrics::Logger.log("#{METRICS_LABEL} #{METRICS_CAPTION}")
        result_str = result.to_s.delete("\n")
        Metrics::Logger.log("#{METRICS_LABEL} #{result_str}")
      end
    end
  end
  
  def real_time(result)
    METRICS_FMTSTR.gsub(/(%[-+\.\d]*)r/){"#{$1}f" % result.real}
  end
  
  def metric_label
    if respond_to?(:controller_name)
      action = action_name 
    	label = "Request to [#{self.class.name}]" 
    else
      label = "#{self.class.name}"
    end
  end
  
  def controller_args
    "action = #{action_name }" + Metrics::Config[:log_delimiter] + "path = #{request.path}?#{request.env['QUERY_STRING']}"
  end

  def self.included(klass)
    klass.send(:extend, Metrics)
  end
  
  def disabled_metric
  end
end

require 'rails/controller_metrics'
require 'ruby/metric_extensions'
require 'rails/activerecord_enhanced_metrics'
require 'ruby/http_metrics'

