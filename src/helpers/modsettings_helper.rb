require_relative "base_helper"

class ModsettingsHelper < BaseHelper
  def initialize(config_helper)
    if config_helper.nil?
      raise ArgumentError, "ModsettingsHelper must accept a valid ConfigHelper."
    end

    @config_helper = config_helper
    @filepath = File.join(self.modsettings_dir, "modsettings.lsx")
  end

  def data
    @data ||= self.get_modsettings

    return @data
  end

  def save(doc, with_logging: false)
    File.open(@filepath, "w") do |f|
      f.write(doc.to_xml)
    end

    if with_logging
      puts "Wrote data to modsettings.lsx."
    end
  end

  def modsettings_dir
    config = @config_helper.data

    File.join(config["paths"]["appdata_dir"], "PlayerProfiles", "Public")
  end

  private

  def get_modsettings
    get_xml_data(@filepath)
  end
end
