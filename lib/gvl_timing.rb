# frozen_string_literal: true

require_relative "gvl_timing/version"
require_relative "gvl_timing/gvl_timing"

module GVLTiming
  class Error < StandardError; end

  class Timer
    def duration
      monotonic_stop - monotonic_start
    end

    def cpu_duration
      cputime_stop - cputime_start
    end
  end
end
