#!/usr/bin/env ruby -w

$LOAD_PATH.unshift(File.expand_path("../../lib", __FILE__))

require "uniq_martin/brew_cli"

module GripCli
  include UniqMartin::BrewCliExtension
  extend self

  def run!
    usage(0) if ARGV.flag?("--help")

    urls = grip_urls.map { |s| "  #{s}" }
    ohai "URLs you might be interested in:", *urls

    args = ["grip"] + ARGV
    HOMEBREW_REPOSITORY.cd do
      ohai args.join(" ")
      safe_system(*args)
    end
  end

  private

  def grip_urls
    base_url = "http://localhost:6419/"
    urls = %W[
      #{base_url}
      #{base_url}Library/Homebrew/
      #{base_url}share/doc/homebrew/
    ]

    Pathname.glob("#{HOMEBREW_REPOSITORY}/share/doc/homebrew/*.md") do |pn|
      file = pn.basename.to_s
      next if file == "README.md"
      urls << "#{base_url}share/doc/homebrew/#{file}"
    end

    urls
  end

  def usage(code = nil)
    puts_usage <<-EOS
NAME
  brew grip - Preview README and other Homebrew documentation using GRIP.

SYNOPSIS
  brew grip [<arguments>...]
  brew grip (-h|--help)

DESCRIPTION
  Starts GRIP (Github Readme Instant Preview) at the root of the Homebrew
  repository and forwards any additional <arguments> to GRIP. If not already
  installed, you might want to install GRIP via `pip install grip`.

OPTIONS
  -h, --help
    Show this usage information and exit.

EOS

    exit(code) unless code.nil?
  end
end

GripCli.run!
