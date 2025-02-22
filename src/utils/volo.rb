# frozen_string_literal: true

require "logger"
require "rainbow"

require_relative "../helpers/config_helper"
require_relative "../helpers/constants"
require_relative "filepaths"

class Volo < Logger
  LOG_LEVEL_MAP = {
    debug: Logger::DEBUG,
    info: Logger::INFO,
    warn: Logger::WARN,
    error: Logger::ERROR
  }.freeze

  def initialize
    FileUtils.mkdir_p(Filepaths.root(Constants::LOGS_DIR))

    super(Filepaths.root(Constants::LOGS_DIR, "zhalk.log"), "daily")

    @config_helper = ConfigHelper.new
  end

  def config
    @config ||= @config_helper.data["logging"]

    return @config
  end

  def info(msg, color = nil)
    self.handle_log(msg, :info, color)
  end

  def debug(msg, color = nil)
    self.handle_log(msg, :debug, color)
  end

  def warn(msg, color = nil)
    self.handle_log(msg, :warn, color)
  end

  def error(msg, color = nil)
    self.handle_log(msg, :error, color)
  end

  def handle_log(msg, level, color = nil)
    lines = msg
    if msg.is_a? String
      lines = if msg == ""
                [""]
              else
                msg.split("\n")
              end
    end

    raise ArgumentError, "Invalid msg for #handle_log." unless lines.is_a? Array

    lines.each { |line| self.add(LOG_LEVEL_MAP[level], line) }

    if self.log_level_matches?(level)
      self.handle_puts(lines, level, color)
    end
  end

  private

  def log_level_matches?(level)
    config_level = self.config["log_level"].to_sym
    levels = LOG_LEVEL_MAP.keys

    return levels.index(level) >= levels.index(config_level)
  end

  def handle_puts(lines, level, color)
    if level == :warn || level == :error || self.config["log_level_in_stdout"]
      lines = lines.map { |line| "#{level.to_s.upcase}: #{line}" }
    end

    if color
      lines.each do |line|
        puts Rainbow(line).color(color)
      end
    elsif level == :warn
      lines.each do |line|
        puts Rainbow(line).yellow
      end
    elsif level == :error
      lines.each do |line|
        puts Rainbow(line).red
      end
    else
      puts lines
    end
  end
end
