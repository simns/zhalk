require "date"

require_relative "base_helper"

class ModDataHelper < BaseHelper
  def data
    @data ||= self.get_json_data("mod-data.json")

    return @data
  end

  def has?(uuid)
    return self.data.has_key?(uuid)
  end

  def set_installed(uuid)
    self.data[uuid]["is_installed"] = true
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

  def save(with_logging: false)
    return if self.data.nil?

    self.save_json_data("mod-data.json", self.data)

    if with_logging
      puts "Wrote data to mod-data.json."
    end
  end
end
