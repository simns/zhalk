require_relative "base_helper"
require_relative "constants"

class InfoJsonHelper < BaseHelper
  attr_reader :uuid
  attr_reader :folder
  attr_reader :name
  attr_reader :md5
  attr_reader :version

  def initialize(mod_name)
    @filepath = File.join(Constants::DUMP_DIR, mod_name, "info.json")
  end

  def file_present?
    return File.exist?(@filepath)
  end

  def load_data
    data = self.get_json_data(@filepath)
    @uuid = data.dig("Mods", 0, "UUID")
    @folder = data.dig("Mods", 0, "Folder")
    @name = data.dig("Mods", 0, "Name")
    @md5 = data.dig("MD5")
    @version = data.dig("Mods", 0, "Version")
  end

  def check_fields!
    if @uuid.nil?
      raise "info.json does not have UUID. Cannot proceed."
    end

    if @folder.nil?
      raise "info.json does not have Folder. Cannot proceed."
    end

    if @name.nil?
      raise "info.json does not have Name. Cannot proceed."
    end
  end
end
