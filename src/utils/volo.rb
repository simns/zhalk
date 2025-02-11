require "logger"
require "rainbow"

require_relative "../helpers/config_helper"
require_relative "../helpers/constants"

class Volo < Logger
  LOG_LEVEL_MAP = {
    debug: Logger::DEBUG,
    info: Logger::INFO,
    warn: Logger::WARN,
    error: Logger::ERROR
  }.freeze

  def initialize(*args)
    FileUtils.mkdir_p(Constants::LOGS_DIR)

    super(*args)

    config_helper = ConfigHelper.new
    @config = config_helper.data["logging"]
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
    if msg.is_a? String
      self.add(LOG_LEVEL_MAP[level], msg)
    elsif msg.is_a? Array
      msg.each { |msg_part| self.add(LOG_LEVEL_MAP[level], msg_part) }
    else
      raise ArgumentError, "Invalid msg for #handle_log."
    end

    if self.log_level_matches?(level)
      self.handle_puts(msg, level, color)
    end
  end

  private

  def log_level_matches?(level)
    config_level = @config["log_level"].to_sym
    levels = LOG_LEVEL_MAP.keys

    return levels.index(level) >= levels.index(config_level)
  end

  def handle_puts(msg, level, color)
    new_msg = msg
    if level == :warn || level == :error
      new_msg = "#{level.to_s.upcase}: #{msg}"
    end

    if color
      puts Rainbow(new_msg).color(color)
    elsif level == :warn
      puts Rainbow(new_msg).yellow
    elsif level == :error
      puts Rainbow(new_msg).red
    else
      puts new_msg
    end
  end
end
