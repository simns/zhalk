require_relative "base_helper"

class ModsettingsHelper < BaseHelper
  def initialize(config_helper)
    if config_helper.nil?
      raise ArgumentError, "ModsettingsHelper must accept a valid ConfigHelper."
    end

    @config_helper = config_helper
  end

  def data
    @data ||= self.get_modsettings

    return @data
  end

  private

  def get_modsettings
    get_xml_data(File.join(modsettings_dir(config), "modsettings.lsx"))
  end

  def modsettings_dir
    config = @config_helper.data

    File.join(config["paths"]["appdata_dir"], "PlayerProfiles", "Public")
  end
end
