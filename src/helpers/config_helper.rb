# frozen_string_literal: true

require "toml"

require_relative "base_helper"
require_relative "../utils/errors"

class ConfigHelper < BaseHelper
  def data
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
