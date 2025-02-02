require_relative "base_cmd"
require_relative "helpers/constants"

class InitCmd < BaseCmd
  def run
    self.safe_mkdir(Constants::MODS_DIR, with_logging: true)
    self.safe_mkdir(Constants::DUMP_DIR, with_logging: true)

    self.safe_cp("conf.toml.template", "conf.toml", with_logging: true)

    self.safe_create("mod-data.json", content: "{}", with_logging: true)

    puts "Done."
  end
end
