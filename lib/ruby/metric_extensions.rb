# CONFIDENTIAL AND PROPRIETARY. © 2007 Revolution Health Group LLC. All rights reserved.

class Module
  def collect_metrics_on(*syms)
    syms.flatten.each do |sym|
      interpose = lambda do |sym|
        alias_method "__metrics_#{sym}__".to_sym, sym
        protected "__metrics_#{sym}__".to_sym
        class_eval <<-EOS
          def #{sym}(*args, &block)
            result = nil
            Metrics.collect_metrics("#{self.name}.#{sym}", *args) do
              result = __metrics_#{sym}__(*args, &block)
            end
            result
          end
        EOS
      end

      if method_defined? sym and (!method_defined?("__metrics_#{sym}__".to_sym))
        class_eval { interpose.call(sym) }
      else
        _metrics_interpose[sym.to_sym] = interpose
      end
    end
    
    if not singleton_methods(false).include?('method_added')
      instance_eval do
        def method_added(method_sym)
            if interpose = _metrics_interpose[method_sym]
              _metrics_interpose.delete method_sym
              class_eval { interpose.call(method_sym) }
            end
            super
        end
      end
    end
  end
  
  def _metrics_interpose
    @metrics_interpose ||= {}
  end
end

