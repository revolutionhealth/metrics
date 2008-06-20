
module Metrics
  module Logger
    extend self
    
    def enabled?
      METRICS_LOGGER.error?
    end
    
    def log(msg)
      METRICS_LOGGER.error(msg)
    end
    
  end
end
