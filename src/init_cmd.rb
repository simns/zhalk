require_relative "base_cmd"

class InitCmd < BaseCmd
  def run
    self.safe_mkdir(MODS_DIR, with_logging: true)
    self.safe_mkdir(DUMP_DIR, with_logging: true)

    self.safe_cp("conf.toml.template", "conf.toml", with_logging: true)

    self.safe_create("mod-data.json", content: "{}", with_logging: true)

    puts "Done."
  end
end
