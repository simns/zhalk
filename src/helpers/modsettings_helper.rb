require_relative "base_helper"

class ModsettingsHelper < BaseHelper
  def initialize(config_helper)
    if config_helper.nil?
      raise ArgumentError, "ModsettingsHelper must accept a valid ConfigHelper."
    end

    @config_helper = config_helper
  end

  def data
    @filepath ||= File.join(self.modsettings_dir, "modsettings.lsx")
    @data ||= self.get_modsettings

    return @data
  end

  def save(doc = nil, with_logging: false)
    File.open(@filepath, "w") do |f|
      if doc
        f.write(doc.to_xml)
      else
        f.write(self.data)
      end
    end

    if with_logging
      puts "Wrote data to modsettings.lsx."
    end
  end

  def modsettings_dir
    config = @config_helper.data

    return File.join(config["paths"]["appdata_dir"], "PlayerProfiles", "Public")
  end

  private

  def get_modsettings
    self.get_xml_data(@filepath)
  end
end
