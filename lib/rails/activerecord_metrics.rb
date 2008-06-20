
module Metrics::ActiveRecordMetrics
  def self.append_features(klass)
    super
    klass.collect_metrics_on(:log)
  end

end

ActiveRecord::ConnectionAdapters::AbstractAdapter.send :include, Metrics::ActiveRecordMetrics

# CONFIDENTIAL AND PROPRIETARY. © 2007 Revolution Health Group LLC. All rights reserved.

