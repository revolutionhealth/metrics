module RHG

if defined?(RHG::ServiceConfig)

  class MetricsTestClass < RHG::Facade::Base
    backend_instance_method :my_method
  
    def self.backend
      @backend || reset_backend(Metrics::MetricsBackendClass)
    end
  end

  class Metrics::MetricsBackendClass
    include RHG::ServiceConfig
    collect_metrics_on :my_method
  
    def my_method(blah = nil)
      print "blah = #{blah}\n" if blah != nil
      true
    end

    def my_non_metric_method(blah = nil)
      print "blah = #{blah}\n" if blah != nil
      true
    end
  
    collect_metrics_on :my_method
  end

else # if not defined ServiceConfig

  class MetricsTestClass
    collect_metrics_on :my_method
  
    def my_method(blah = nil)
      print "blah = #{blah}\n" if blah != nil
      true
    end

    def my_non_metric_method(blah = nil)
      print "blah = #{blah}\n" if blah != nil
      true
    end
  
    collect_metrics_on :my_method
  end
end # end if defined?

end
# CONFIDENTIAL AND PROPRIETARY. © 2007 Revolution Health Group LLC. All rights reserved.
# This source code may not be disclosed to others, used or reproduced without the written permission of Revolution Health Group.
