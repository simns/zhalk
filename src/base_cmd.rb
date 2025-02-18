# frozen_string_literal: true

require "fileutils"
require "rainbow"

require_relative "helpers/config_helper"
require_relative "helpers/mod_data_helper"
require_relative "helpers/modsettings_helper"
require_relative "helpers/constants"
require_relative "utils/errors"
require_relative "utils/volo"

class BaseCmd
  def initialize
    @logger = Volo.new

    @config_helper = ConfigHelper.new
    @mod_data_helper = ModDataHelper.new(@logger)
    @modsettings_helper = ModsettingsHelper.new(@config_helper, @logger)
  end

  def run(*args)
    if args[0] == "--help"
      puts self.help
    else
      self.main(args)
    end
  rescue ConfigNotFoundError => error
    puts Rainbow(error.detailed_message).red
  rescue StandardError => error
    @logger.error(error.message)
    @logger.debug(error.backtrace)
  end

  def main(_args)
    raise NoMethodError
  end

  def help
    raise NoMethodError
  end

  def safe_mkdir(name, log_level: :debug)
    @logger.debug("Starting safe_mkdir for #{name}")

    if !Dir.exist?(name)
      Dir.mkdir(name)
      @logger.handle_log("Created dir \"#{name}\".", log_level)
    else
      @logger.handle_log("Dir \"#{name}\" already exists.", log_level)
    end
  end

  def safe_cp(src, dest, log_level: :debug)
    updated_dest = dest
    basename = File.basename(src)
    if File.directory?(dest)
      updated_dest = File.join(dest, basename)
    end

    if !File.exist?(updated_dest)
      FileUtils.cp(src, updated_dest)
      @logger.handle_log("Created file #{File.basename(updated_dest)}.", log_level)
      return true
    else
      @logger.handle_log("File #{File.basename(updated_dest)} already exists.", log_level)
      return false
    end
  end

  def safe_create(filename, content: "", log_level: :debug)
    if !File.exist?(filename)
      File.write(filename, content)
      @logger.handle_log("Created file #{filename}.", log_level)
    else
      @logger.handle_log("File #{filename} already exists.", log_level)
    end
  end

  def num_mods(num, type = nil)
    mod_noun = num == 1 ? "mod" : "mods"

    return [num, type, mod_noun].compact.join(" ")
  end

  def num?(num)
    return num.to_i.to_s == num.strip
  end
end
