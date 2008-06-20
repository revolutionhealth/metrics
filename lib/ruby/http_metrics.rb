# CONFIDENTIAL AND PROPRIETARY. © 2007 Revolution Health Group LLC. All rights reserved.
require 'net/http'

module Net
  class HTTPGenericRequest
    alias_method :__non_metrics_exec, :exec
    def exec(sock, ver, path, &block)
      Metrics.collect_metrics("#{self.class.name}.exec", "HTTP/#{ver}", "path= #{path}") do
        __non_metrics_exec(sock, ver, path, &block)
      end
    end
  end
end
