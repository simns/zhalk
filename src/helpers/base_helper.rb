# frozen_string_literal: true

require "json"
require "nokogiri"

class BaseHelper
  def get_xml_data(filename)
    File.open(filename) do |file|
      return Nokogiri::XML(file, &:noblanks)
    end
  end

  def get_json_data(filename)
    File.open(filename) do |file|
      return JSON.load_file(file)
    end
  end

  def save_json_data(filename, hash)
    File.open(filename, "w") do |file|
      file.write(JSON.pretty_generate(hash))
    end
  end
end
