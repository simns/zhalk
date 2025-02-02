require "fileutils"

require_relative "helpers/config_helper"
require_relative "helpers/mod_data_helper"
require_relative "helpers/modsettings_helper"

class BaseCmd
  def initialize
    self.check_requirements!

    @config_helper = ConfigHelper.new
    @mod_data_helper = ModDataHelper.new
    @modsettings_helper = ModsettingsHelper.new(@config_helper)
  end

  def run
    raise NoMethodError
  end

  def safe_mkdir(name, with_logging: false)
    if !Dir.exist?(name)
      Dir.mkdir(name)
      puts "Created dir \"#{name}\"." if with_logging
    else
      puts "Dir \"#{name}\" already exists." if with_logging
    end
  end

  def safe_cp(src, dest, with_logging: false)
    updated_dest = dest
    basename = File.basename(src)
    if File.directory?(dest)
      updated_dest = File.join(dest, basename)
    end

    if !File.exist?(updated_dest)
      FileUtils.cp(src, updated_dest)
      puts "Created file #{File.basename(updated_dest)}." if with_logging
      return true
    else
      puts "File #{File.basename(updated_dest)} already exists." if with_logging
      return false
    end
  end

  def safe_create(filename, content: "", with_logging: false)
    if !File.exist?(filename)
      File.write(filename, content)
      puts "Created file #{filename}." if with_logging
    else
      puts "File #{filename} already exists." if with_logging
    end
  end

  def num_mods(num, type)
    num == 1 ? "1 #{type} mod" : "#{num} #{type} mods"
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
