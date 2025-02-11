require "fileutils"

require_relative "helpers/config_helper"
require_relative "helpers/mod_data_helper"
require_relative "helpers/modsettings_helper"
require_relative "helpers/constants"
require_relative "utils/volo"

class BaseCmd
  def initialize
    @config_helper = ConfigHelper.new
    @mod_data_helper = ModDataHelper.new
    @modsettings_helper = ModsettingsHelper.new(@config_helper)

    @logger = Volo.new(File.join(Constants::LOGS_DIR, "zhalk.log"), "daily")
  end

  def run(*args)
    if args[0] == "--help"
      puts self.help
    else
      self.main(args)
    end
  end

  def main(args)
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

  def num_mods(num, type)
    num == 1 ? "1 #{type} mod" : "#{num} #{type} mods"
  end

  def num?(num)
    return num.to_i.to_s == num.strip
  end

  private

  def check_requirements!
    if !File.exist?("mod-data.json")
      raise "mod-data.json does not exist. Make sure to run the 'init' command."
    end
    if !File.exist?("conf.toml")
      raise "No conf.toml found. Make sure to run the 'init' command."
    end
  end
end
