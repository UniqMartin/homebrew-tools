#!/usr/bin/env ruby -w

$LOAD_PATH.unshift(File.expand_path("../../lib", __FILE__))

require "uniq_martin/brew_cli"

module MachoFindCli
  include UniqMartin::BrewCliExtension
  extend self

  def run!
    usage(0) if ARGV.flag?("--help")

    @troublemakers = []
    dirs = dirs_from_argv(ARGV.named)
    dirs.each { |dir| macho_find(dir) }
    output_summary
  end

  private

  def output_summary
    return if @troublemakers.empty?
    puts "\nFiles that caused errors (rerun with '--debug' to investigate):"
    puts "  #{@troublemakers.join("\n  ")}"
  end

  def dirs_from_argv(argv)
    raise "Expected at least one named argument." if argv.empty?
    dirs = []
    argv.each do |arg|
      dir = Pathname.new(arg)
      raise "Expected path '#{dir}' to be absolute." unless dir.absolute?
      raise "Expected path '#{dir}' to exist." unless dir.exist?
      raise "Expected path '#{dir}' to be a directory." unless dir.directory?
      dirs << dir
    end
    dirs
  end

  def macho_find(dir)
    dir.find do |pn|
      next if pn.symlink? || pn.directory?
      poke_one_file(pn)
    end
  end

  def poke_one_file(pn)
    puts pn if pn.mach_o_bundle? || pn.dylib? || pn.mach_o_executable?
  rescue
    raise if ARGV.debug?
    @troublemakers << pn
  end

  def usage(code = nil) # rubocop:disable Metrics/MethodLength
    puts_usage <<-EOS
NAME
  brew macho-find - Recursively list all Mach-O files in given directories.

SYNOPSIS
  brew macho-find <directories>...
  brew macho-find (-h|--help)

DESCRIPTION
  Scans the given directory or list of directories for Mach-O files and outputs
  their full paths, one path per line. If a list of directories is given, scans
  them in order without checking for duplicates or overlaps, possibly yielding
  the same path multiple times. The effect is very similar to `find` if it had
  a filter for Mach-O files.

  Only a subset of all Mach-O file types are recognized, namely bundles, dylibs,
  and executables. Fat binaries (sometimes called universal binaries) are also
  supported. Architecture support is limited to desktop CPUs relevant to OS X,
  namely 32/64-bit variants of x86 (since 10.4) and PowerPC (until 10.5).

OPTIONS
  -d, --debug
    If given, an error encountered while processing the files will interrupt the
    run and a stack trace will be printed. Otherwise, processing will resume and
    a summary of files that caused errors will be printed at the end.

  -h, --help
    Show this usage information and exit.

EXAMPLES
  List all Mach-O files in the cellar of the active Homebrew installation:

    $ brew macho-find "$(brew --cellar)"

EOS

    exit(code) unless code.nil?
  end
end

MachoFindCli.run!
