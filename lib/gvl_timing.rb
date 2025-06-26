# frozen_string_literal: true

require_relative "gvl_timing/version"
require_relative "gvl_timing/gvl_timing"

module GVLTiming
  class Error < StandardError; end

  class << self
    def measure
      timer = Timer.new
      timer.start
      begin
        yield
      ensure
        timer.stop
      end
      timer
    end
    alias_method :time, :measure
  end

  class Timer
    NANOSECONDS_PER_SECOND_F = 1000000000.0

    def duration_ns
      monotonic_stop_ns - monotonic_start_ns
    end

    def cpu_duration_ns
      cputime_stop_ns - cputime_start_ns
    end

    [
      :duration, :cpu_duration,
      :monotonic_start, :monotonic_stop,
      :cputime_start, :cputime_stop,
      :running_duration, :stalled_duration, :idle_duration
    ].each do |name|
      class_eval <<~RUBY
        def #{name}(unit = :float_second)
          scale_ns(#{name}_ns, unit)
        end
      RUBY
    end

    alias releases_count yields_count

    def inspect
      "#<#{self.class} total=%.2fs running=%.2fs idle=%.2fs stalled=%.2fs yields=%d>" % [
        duration,
        running_duration,
        idle_duration,
        stalled_duration,
        yields_count,
      ]
    end

    private

    def scale_ns(value_ns, unit)
      case unit
      when :float_second
        value_ns / 1_000_000_000.0
      when :float_millisecond
        value_ns / 1_000_000.0
      when :float_microsecond
        value_ns / 1000.0
      when :second
        value_ns / 1_000_000_000
      when :millisecond
        value_ns / 1_000_000
      when :microsecond
        value_ns / 1000
      when :nanosecond
        value_ns
      else
        raise ArgumentError, "unexpected unit: #{unit.inspect}"
      end
    end
  end
end
