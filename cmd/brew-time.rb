#!/usr/bin/env ruby -w

$LOAD_PATH.unshift(File.expand_path("../../lib", __FILE__))

require "uniq_martin/brew_cli"
require "benchmark"

module TimeCli
  include UniqMartin::BrewCliExtension
  extend self

  def run!
    usage(0) if ARGV.flag?("--help")

    info = Benchmark.measure { system HOMEBREW_PREFIX.join("bin/brew"), *ARGV }
    $stderr.puts "brew #{ARGV.first}: #{format_result(info)}"
  end

  private

  def format_result(info)
    args = [
      info.utime + info.cutime,
      info.stime + info.cstime,
      info.real,
      100 * info.total / info.real,
    ]
    format("%7.3fs user, %7.3fs system, %7.3fs total (%5.1f%% cpu)", *args)
  end

  def usage(code = nil)
    puts_usage <<-EOS
NAME
  brew time - Time execution of a Homebrew command.

SYNOPSIS
  brew time <command> [<arguments>...]
  brew time (-h|--help)

DESCRIPTION
  Executes the Homebrew command <command> and reports on the CPU utilization in
  a manner similar to `time` (dumped to standard error on exit).

OPTIONS
  -h, --help
    Show this usage information and exit.

EXAMPLES
  Time how long it takes for `brew doctor` to run all its checks.

    $ brew time doctor

EOS

    exit(code) unless code.nil?
  end
end

TimeCli.run!
