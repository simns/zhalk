require "pp"
require "fakefs/spec_helpers"

require_relative "../src/init"

RSpec.describe "init.rb" do
  include FakeFS::SpecHelpers

  describe "#init_cmd" do
    before do
      allow(self).to receive(:puts)
      allow(self).to receive(:refresh_cmd)
    end

    context "when no init items are present" do
      before do
        FileUtils.touch("conf.toml.template")

        init_cmd
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
        FileUtils.touch("conf.toml.template")
        FileUtils.touch("conf.toml")

        FileUtils.mkdir("mods")
        FileUtils.mkdir("dump")

        File.write("mod-data.json", "{}")

        init_cmd
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
