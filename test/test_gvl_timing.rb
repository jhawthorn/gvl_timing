# frozen_string_literal: true

require "test_helper"

class TestGVLTiming < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::GVLTiming::VERSION
  end

  def test_timing_idle_sleep
    timer = GVLTiming::Timer.new
    timer.start
    sleep 0.1
    timer.stop

    assert_in_delta 100000000, timer.duration, 5000000
    assert_in_delta 100000000, timer.idle_duration, 5000000
    assert_in_delta 0, timer.cpu_duration, 5000000
    assert_in_delta 0, timer.stalled_duration, 5000000
    assert_in_delta 0, timer.running_duration, 5000000
  end

  def test_timing_busy_sleep
    timer = GVLTiming::Timer.new
    timer.start
    target = Process::clock_gettime(Process::CLOCK_MONOTONIC) + 0.1
    while Process::clock_gettime(Process::CLOCK_MONOTONIC) < target
      # busy
    end
    timer.stop

    assert_in_delta 100000000, timer.duration, 5000000
    assert_in_delta 100000000, timer.running_duration, 5000000
    #assert_in_delta 100000000, timer.cpu_duration, 10000000
    assert_in_delta 0, timer.stalled_duration, 5000000
    assert_in_delta 0, timer.idle_duration, 5000000
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

    timer = GVLTiming::Timer.new
    timer.start
    wait.unlock
    until done
      Thread.pass
    end
    timer.stop

    assert_in_delta 100000000, timer.duration, 5000000
    assert_in_delta 100000000, timer.stalled_duration, 5000000
    assert_in_delta 0, timer.cpu_duration, 5000000
    assert_in_delta 0, timer.running_duration, 5000000
    assert_in_delta 0, timer.idle_duration, 5000000
  ensure
    thread&.kill
  end

  def test_measure_and_inspect
    timer = GVLTiming.measure { sleep 0.1 }
    expected = "#<GVLTiming::Timer total=0.10 running=0.00 idle=0.10 stalled=0.00>"
    assert_equal expected, timer.inspect
  end
end
