# frozen_string_literal: true

require_relative "base_helper"
require_relative "constants"
require_relative "../utils/filepaths"

class InfoJsonHelper < BaseHelper
  attr_reader :uuid, :folder, :name, :md5, :version

  def initialize(mod_name)
    @filepath = Filepaths.dump(mod_name, "info.json")
  end

  def file_present?
    return File.exist?(@filepath)
  end

  def load_data
    data = self.get_json_data(@filepath)
    @uuid = data.dig("Mods", 0, "UUID")
    @folder = data.dig("Mods", 0, "Folder")
    @name = data.dig("Mods", 0, "Name")
    @md5 = data["MD5"]
    @version = data.dig("Mods", 0, "Version")
  end

  def check_fields!
    raise "info.json does not have UUID. Cannot proceed." if @uuid.nil?

    raise "info.json does not have Folder. Cannot proceed." if @folder.nil?

    raise "info.json does not have Name. Cannot proceed." if @name.nil?
  end
end
