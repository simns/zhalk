require "toml"

require_relative "base_helper"

class ConfigHelper < BaseHelper
  def data
    @data ||= get_toml_config

    return @data
  end

  private

  def get_toml_config
    TOML.load_file("conf.toml")
  end
end
