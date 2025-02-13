require "date"

require_relative "base_helper"

class ModDataHelper < BaseHelper
  def initialize(logger)
    @logger = logger
  end

  def data
    @data ||= self.get_json_data("mod-data.json")

    return @data
  end

  def has?(uuid)
    return self.data.has_key?(uuid)
  end

  def set_installed(uuid, is_installed = true)
    self.data[uuid]["is_installed"] = is_installed
  end

  def installed?(uuid)
    return self.data.dig(uuid, "is_installed")
  end

  def set_updated(uuid)
    self.data[uuid]["updated_at"] = Time.now.to_s
  end

  def add_standard_entry(uuid, name)
    new_number = if self.data.values.size == 0
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

    self.save_json_data("mod-data.json", self.data)

    @logger.handle_log("Wrote data to mod-data.json.", log_level)
  end
end
