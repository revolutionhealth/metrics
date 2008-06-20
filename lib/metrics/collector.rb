# CONFIDENTIAL AND PROPRIETARY. © 2007 Revolution Health Group LLC. All rights reserved.

class Metrics::Collector
  def begin_metric()
    @metric_begin_measurement = Process.times
    @metric_begin_measurement_time = Time.now
  end
    
  def end_metric(metric_label)
    end_metric_measurement = Process.times
    end_metric_measurement_time = Time.now

    result = Benchmark::Tms.new(end_metric_measurement.utime - @metric_begin_measurement.utime,
                                end_metric_measurement.stime - @metric_begin_measurement.stime,
                                end_metric_measurement.cutime - @metric_begin_measurement.cutime,
                                end_metric_measurement.cstime - @metric_begin_measurement.cstime,
                                end_metric_measurement_time.to_f - @metric_begin_measurement_time.to_f,
                                metric_label)
  end
end
