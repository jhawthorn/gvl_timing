# frozen_string_literal: true

require "test_helper"

class TestGVLGlobalTiming < Minitest::Test
  def test_timing_idle_sleep
    timer = GVLTiming::GlobalTimer.new
    timer.start
    Thread.new { sleep 0.1 }.join
    timer.stop

    assert_in_delta 100_000_000, timer.duration_ns, 6_000_000
    assert_in_delta 100_000_000, timer.running_duration_ns, 6_000_000
    assert_in_delta 0, timer.stalled_duration_ns, 1_000_000
    assert_in_delta 200_000_000, timer.idle_duration_ns, 6_000_000
    assert_equal 2, timer.releases_count
  end

  private

  def test_timing_busy_sleep
    timer = GVLTiming::GlobalTimer.new
    timer.start

    Thread.new {
      target = Process::clock_gettime(Process::CLOCK_MONOTONIC) + 0.1

      while Process::clock_gettime(Process::CLOCK_MONOTONIC) < target
        # busy
      end
    }.join

    timer.stop

    assert_in_delta 100000000, timer.duration_ns, 5000000
    assert_in_delta 100000000, timer.running_duration_ns, 5000000
    assert_in_delta 0, timer.stalled_duration_ns, 5000000
    assert_in_delta 100000000, timer.idle_duration_ns, 5000000
  end

  def test_timing_stalled_sleep
    done = false
    wait = Mutex.new
    wait.lock
    thread = Thread.new do
      wait.lock
      target = Process::clock_gettime(Process::CLOCK_MONOTONIC) + 0.1
      while Process::clock_gettime(Process::CLOCK_MONOTONIC) < target
        # busy
      end
      done = true
    end


    timer = GVLTiming::GlobalTimer.new
    timer.start

    Thread.new { sleep 0.1 }

    wait.unlock
    Thread.pass
    until done
      Thread.pass
    end
    timer.stop

    assert_in_delta 100000000, timer.duration_ns, 5000000
    assert_in_delta 100000000, timer.running_duration_ns, 5000000
    assert_in_delta 100000000, timer.stalled_duration_ns, 5000000
    assert_in_delta 0, timer.idle_duration_ns, 5000000
  ensure
    thread&.kill
  end

  # def test_timing_units
  #   timer = GVLTiming.measure { sleep 0.1 }
  #
  #   assert_in_delta 100000000, timer.duration_ns, 5000000
  #   assert_in_delta 0.1, timer.duration, 0.005
  #   assert_in_delta 0.1, timer.duration(:float_second), 0.005
  #   assert_in_delta 100, timer.duration(:float_millisecond), 5
  #   assert_in_delta 100_000, timer.duration(:float_microsecond), 5000
  #
  #   assert_equal 0, timer.duration(:second)
  #   assert_in_delta 100, timer.duration(:millisecond), 5
  #   assert_in_delta 100_000, timer.duration(:microsecond), 5_000
  #   assert_in_delta 100_000_000, timer.duration(:nanosecond), 5_000_000
  # end
  #
  # def test_measure_and_inspect
  #   timer = GVLTiming.measure { sleep 0.1 }
  #   expected = "#<GVLTiming::Timer total=0.10s running=0.00s idle=0.10s stalled=0.00s yields=1>"
  #   assert_equal expected, timer.inspect
  # end

  private

  def fib(n)
    return n if n < 2
    fib(n - 1) + fib(n - 2)
  end
end
