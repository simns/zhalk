# frozen_string_literal: true

require "toml"

require_relative "base_helper"

class ConfigHelper < BaseHelper
  def data
    @data ||= self.toml_config

    return @data
  end

  private

  def toml_config
    TOML.load_file("conf.toml")
  end
end
