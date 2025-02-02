require_relative "base_helper"

class ModDataHelper < BaseHelper
  def data
    @data ||= self.get_json_data("mod-data.json")

    return @data
  end

  def save(with_logging: false)
    return if @data.nil?

    self.save_json_data("mod-data.json", @data)

    if with_logging
      puts "Wrote mod-data.json."
    end
  end
end
