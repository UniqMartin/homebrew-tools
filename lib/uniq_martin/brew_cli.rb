# Refuse to run on ancient Ruby version.
unless RUBY_VERSION.split(".").first.to_i >= 2
  abort("Error: Need Ruby 2.0 or newer to run.")
end

# Only accept invocation via `brew`.
unless defined?(HOMEBREW_LIBRARY_PATH)
  brew_command = File.basename($PROGRAM_NAME, ".rb").split("-", 2).join(" ")
  abort("Error: Please run via `#{brew_command}`.")
end

require "uniq_martin/extend/tty"

module UniqMartin
  module BrewCliExtension
    def debug?
      ARGV.include?("--chatty")
    end

    def debug(message)
      return unless debug?
      puts "#{Tty.purple}[debug]#{Tty.reset} #{message}"
    end

    def puts_usage(text)
      puts highlight_sections(text)
    end

    private

    def highlight_sections(text)
      text.gsub(/^[A-Z][A-Z ]*$/, "#{Tty.white}\\0#{Tty.reset}")
    end
  end
end
