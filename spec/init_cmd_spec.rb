# frozen_string_literal: true

require "pp"
require "fakefs/spec_helpers"

require_relative "../src/init_cmd"
require_relative "../src/utils/volo"

RSpec.describe InitCmd do
  include FakeFS::SpecHelpers

  describe "#run" do
    let(:init_cmd) { InitCmd.new }

    before do
      stub_const("ROOT_DIR", ".")

      FileUtils.mkdir(Constants::LOGS_DIR)
      File.write(File.join(Constants::LOGS_DIR, "zhalk.log"), "")

      FileUtils.touch("conf.toml.template")
    end

    context "when no init items are present" do
      before do
        init_cmd.run
      end

      it "creates the init files" do
        expect(Dir.exist?("mods")).to be(true)
        expect(Dir.exist?("dump")).to be(true)
        expect(File.exist?("conf.toml")).to be(true)
        expect(File.read("mod-data.json")).to eq("{}")
      end
    end

    context "when all init items are present" do
      before do
        File.write(
          "conf.toml",
          <<~CONF
            [paths]
            appdata_dir = "."

            [logging]
            log_level = "info"
            log_level_in_stdout = false
          CONF
        )

        FileUtils.mkdir("mods")
        FileUtils.mkdir("dump")

        File.write("mod-data.json", "{}")

        init_cmd.run
      end

      it "creates nothing" do
        expect(Dir.exist?("mods")).to be(true)
        expect(Dir.exist?("dump")).to be(true)
        expect(File.exist?("conf.toml")).to be(true)
        expect(File.read("mod-data.json")).to eq("{}")
      end
    end
  end
end
