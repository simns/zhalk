# frozen_string_literal: true

require_relative "../helpers/constants"

class Filepaths
  def self.root(*fileparts)
    return File.join(ROOT_DIR, *fileparts)
  end

  def self.inactive(*fileparts)
    return File.join(ROOT_DIR, Constants::INACTIVE_DIR, *fileparts)
  end

  def self.dump(*fileparts)
    return File.join(ROOT_DIR, Constants::DUMP_DIR, *fileparts)
  end

  def self.mods(*fileparts)
    return File.join(ROOT_DIR, Constants::MODS_DIR, *fileparts)
  end
end
