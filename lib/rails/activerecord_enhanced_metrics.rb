
if defined?(RAILS_ROOT)
  class ActiveRecord::ConnectionAdapters::AbstractAdapter


    protected
    alias_method :non_metrics_log, :log
    def log(sql, name, &block)
      if @config
        host = @config[:host].sub(/\..*/, '') if @config[:host]
        host = @config[:host] if host.nil? || !host.scan(/^\d+$/).empty?
        connection_info = "#{@config[:username]} #{host} #{@config[:database]}"
      else
        connection_info = "localhost"
      end
      label = "#{self.class.name.sub(/.*\:\:/, '')}.log"
      result = nil
      Metrics.collect_metrics(label, connection_info ||= "no db config", sql) do
        result = non_metrics_log(sql, name, &block)
      end
      result
    end
  end
end

# CONFIDENTIAL AND PROPRIETARY. © 2007 Revolution Health Group LLC. All rights reserved.

