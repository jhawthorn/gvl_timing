# frozen_string_literal: true

require_relative "gvl_timing/version"
require_relative "gvl_timing/gvl_timing"

module GVLTiming
  class Error < StandardError; end

  class << self
    def measure
      timer = Timer.new
      timer.start
      yield
      timer.stop
      timer
    end
    alias_method :time, :measure
  end

  class Timer
    NANOSECONDS_PER_SECOND_F = 1000000000.0

    def duration
      monotonic_stop - monotonic_start
    end

    def cpu_duration
      cputime_stop - cputime_start
    end

    def inspect
      "#<#{self.class} total=%.2fs running=%.2fs idle=%.2fs stalled=%.2fs>" % [
        duration / NANOSECONDS_PER_SECOND_F,
        running_duration / NANOSECONDS_PER_SECOND_F,
        idle_duration / NANOSECONDS_PER_SECOND_F,
        stalled_duration / NANOSECONDS_PER_SECOND_F
      ]
    end
  end
end
