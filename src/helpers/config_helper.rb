# frozen_string_literal: true

require "toml"

require_relative "base_helper"
require_relative "../utils/errors"
require_relative "../../root"

class ConfigHelper < BaseHelper
  def data
    puts "Now fetching #{File.join(ROOT_DIR, "conf.toml")}"
    if !File.exist?(File.join(ROOT_DIR, "conf.toml"))
      raise ConfigNotFoundError, "No conf.toml found. Make sure to run the 'init' command."
    end

    @data ||= self.toml_config

    return @data
  end

  private

  def toml_config
    TOML.load_file(File.join(ROOT_DIR, "conf.toml"))
  end
end
