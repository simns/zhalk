# frozen_string_literal: true

require "date"

require_relative "base_helper"
require_relative "../utils/filepaths"

class ModDataHelper < BaseHelper
  def initialize(logger)
    @logger = logger
  end

  def data
    if !File.exist?(Filepaths.root("mod-data.json"))
      raise "mod-data.json does not exist. Make sure to run the 'init' command."
    end

    @data ||= self.get_json_data(Filepaths.root("mod-data.json"))

    return @data
  end

  def has?(uuid)
    return self.data.key?(uuid)
  end

  def set_installed(uuid, is_installed: true)
    self.data[uuid]["is_installed"] = is_installed
  end

  def installed?(uuid)
    return self.data.dig(uuid, "is_installed")
  end

  def set_updated(uuid)
    self.data[uuid]["updated_at"] = Time.now.to_s
  end

  def add_standard_entry(uuid, name)
    new_number = if self.data.values.empty?
                   1
                 else
                   self.data.values.map { |mod| mod["number"] }.max + 1
                 end

    self.data[uuid] = {
      "is_installed" => true,
      "mod_name" => name,
      "type" => "standard",
      "uuid" => uuid,
      "number" => new_number,
      "created_at" => Time.now.to_s,
      "updated_at" => Time.now.to_s
    }
  end

  def add_modsettings_entry(uuid, name, number)
    self.data[uuid] = {
      "is_installed" => true,
      "mod_name" => name,
      "type" => "from_modsettings",
      "uuid" => uuid,
      "number" => number,
      "created_at" => Time.now.to_s,
      "updated_at" => Time.now.to_s
    }
  end

  def save(log_level: :debug)
    return if self.data.nil?

    self.save_json_data(Filepaths.root("mod-data.json"), self.data)

    @logger.handle_log("Wrote data to mod-data.json.", log_level)
  end
end
