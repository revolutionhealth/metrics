# CONFIDENTIAL AND PROPRIETARY. © 2007 Revolution Health Group LLC. All rights reserved.

require 'singleton'

module Metrics
  class Config
    include Singleton
    
    def initialize
      default_values = { :min_real_time_threshold => 0.1,
                         :log_delimiter => "|",
                         :enhanced_active_record_metrics => false,
                         :single_line_output => false,
                         :metrics_tracking_id => true }
      
      @cfg = default_values.merge(cfg)
    end
    
    def self.[](key)
      Metrics::Config.instance.cfg[key]
    end
    
    def self.[]=(key, value)
      Metrics::Config.instance.cfg[key] = value
    end
    
    
    def cfg
      @cfg ||= load_config
    end

    private
    
    def load_config
      loaded_config = {}
      if defined? ConfigLoader
        loaded_config = ConfigLoader.load_section('metrics.yml')
      else
        config = ""
        config = File.join(RAILS_ROOT, 'config/metrics.yml') if defined?(RAILS_ROOT)
        config = File.join(File.dirname(__FILE__), '../../config/metrics.yml') if not File.exist?(config)
        File.open( config ) { |yf| loaded_config = YAML.load(yf) }
        if defined?(RAILS_ENV)
          loaded_config = loaded_config[RAILS_ENV] || {}
        else
          loaded_config = {}
        end
      end
      loaded_config.symbolize_keys!
    end
  end
end
