# CONFIDENTIAL AND PROPRIETARY. © 2007 Revolution Health Group LLC. All rights reserved.

if defined?(RAILS_ROOT)
  module ActionController
    class Base
      include Metrics

      prepend_before_filter :begin_metric
      append_after_filter :end_metric


    end

  end
end