# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "gvl_timing"

ENV["MT_CPU"] = "0"
require "minitest/autorun"
