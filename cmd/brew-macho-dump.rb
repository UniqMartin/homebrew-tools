#!/usr/bin/env ruby -w

$LOAD_PATH.unshift(File.expand_path("../../lib", __FILE__))

require "uniq_martin/brew_cli"

module MachoDumpCli
  include UniqMartin::BrewCliExtension
  extend self

  def run!
    usage(0) if ARGV.flag?("--help")

    dirs = dirs_from_argv(ARGV.named)
    dirs.each { |dir| macho_dump(dir) }
  end

  private

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

  def macho_dump(dir)
    dir.find do |pn|
      next if pn.symlink? || pn.directory?
      next unless pn.mach_o_bundle? || pn.dylib? || pn.mach_o_executable?
      dump_one_file(pn)
    end
  end

  def dump_one_file(pn)
    if ARGV.flag?("--wide")
      prefix = "#{pn}:"
    else
      puts "#{pn}:"
      prefix = "    "
    end
    puts "#{prefix}kind=#{format_kind(pn)}"
    puts "#{prefix}arch=#{format_arch(pn)}"
    puts "#{prefix}dylib_id=#{pn.dylib_id}" if pn.dylib_id
    dylibs = pn.dynamically_linked_libraries.sort
    dylibs.each do |dylib|
      puts "#{prefix}dylib_load=#{dylib}"
    end
  end

  def format_arch(pn)
    "[" + pn.archs.join(",") + "]"
  end

  def format_kind(pn)
    if pn.mach_o_bundle?
      "bundle"
    elsif pn.dylib?
      "dylib"
    elsif pn.mach_o_executable?
      "executable"
    else
      "unknown"
    end
  end

  def usage(code = nil) # rubocop:disable Metrics/MethodLength
    puts_usage <<-EOS
NAME
  brew macho-dump - Dump information about Mach-O files in given directories.

SYNOPSIS
  brew macho-dump [-w|--wide] <directories>...
  brew macho-dump (-h|--help)

DESCRIPTION
  Scans the given directory or list of directories for Mach-O files and outputs
  their full paths. Every such path is followed by a variable number of indented
  lines that contain information about the file type (one of bundle, dylib, or
  executable), the supported architectures, the dylib ID (install name; only for
  dylibs), and a possibly empty list of dylibs the file links to. The general
  format of the output is:

    <file>:
        <property1>=<value1>
        <property2>=<value2>
        …

  Example for a binary from the 'xz' formula:

    /usr/local/Cellar/xz/5.2.2/bin/xz:
        kind=executable
        arch=[x86_64]
        dylib_load=/usr/local/Cellar/xz/5.2.2/lib/liblzma.5.dylib
        dylib_load=/usr/lib/libSystem.B.dylib

  Only a subset of all Mach-O file types are recognized, namely bundles, dylibs,
  and executables. Fat binaries (sometimes called universal binaries) are also
  supported. Architecture support is limited to desktop CPUs relevant to OS X,
  namely 32/64-bit variants of x86 (since 10.4) and PowerPC (until 10.5).

OPTIONS
  -h, --help
    Show this usage information and exit.

  -w, --wide
    If given, generates output in the '<file>:<property>=<value>' format. Thus,
    the file name is repeated for every property of a file. This format is wider
    and more repetitive, but better suited for parsing and grepping.

EXAMPLES
  List all Mach-O files with their properties in the cellar of the active
  Homebrew installation:

    $ brew macho-dump "$(brew --cellar)"

EOS

    exit(code) unless code.nil?
  end
end

MachoDumpCli.run!
