# frozen_string_literal: true

require "toml"

require_relative "base_helper"
require_relative "../utils/errors"
require_relative "../utils/filepaths"

class ConfigHelper < BaseHelper
  PLACEHOLDER_CONFIG = {
    "logging" => {
      "log_level" => "info"
    }
  }.freeze

  def initialize(ignore_not_found: false)
    @ignore_not_found = ignore_not_found
  end

  def data
    if !File.exist?(Filepaths.root("conf.toml"))
      return PLACEHOLDER_CONFIG if @ignore_not_found

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
