# frozen_string_literal: true

require_relative "base_helper"

class ModsettingsHelper < BaseHelper
  def initialize(config_helper, logger)
    raise ArgumentError, "ModsettingsHelper must accept a valid ConfigHelper." if config_helper.nil?

    @config_helper = config_helper
    @logger = logger
  end

  def data
    @filepath ||= File.join(self.modsettings_dir, "modsettings.lsx")
    @data ||= self.get_modsettings

    return @data
  end

  def save(doc = nil, log_level: :debug)
    File.open(@filepath, "w") do |f|
      if doc
        f.write(doc.to_xml)
      else
        f.write(self.data)
      end
    end

    @logger.handle_log("Wrote data to modsettings.lsx.", log_level)
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
