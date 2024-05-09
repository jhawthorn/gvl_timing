# frozen_string_literal: true

require "bundler/gem_tasks"
require "minitest/test_task"

Minitest::TestTask.create

require "rake/extensiontask"

task build: :compile

GEMSPEC = Gem::Specification.load("gvl_timing.gemspec")

Rake::ExtensionTask.new("gvl_timing", GEMSPEC) do |ext|
  ext.lib_dir = "lib/gvl_timing"
end

task default: %i[clobber compile test]
