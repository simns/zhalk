require "pp"
require "fakefs/spec_helpers"

require_relative "../src/refresh"

RSpec.describe "refresh.rb" do
  include FakeFS::SpecHelpers

  describe "#refresh_cmd" do
    context "when there is nothing in the modsettings" do
      before do
        File.write("mod-data.json", "{}")
        File.write("modsettings.lsx",
                   <<-MODSETTINGS
<?xml version="1.0" encoding="UTF-8"?>
<save>
  <version major="4" minor="7" revision="1" build="300"/>
  <region id="ModuleSettings">
    <node id="root">
      <children>
        <node id="Mods">
          <children>
          </children>
        </node>
      </children>
    </node>
  </region>
</save>
MODSETTINGS
        )

        allow(self).to receive(:puts)
        allow(self).to receive(:get_toml_config).and_return({})
        allow(self).to receive(:modsettings_dir).and_return(".")

        refresh_cmd
      end

      it "doesn't add anything to mod-data.json" do
        expect(File.read("mod-data.json")).to eq("{}")
      end
    end

    context "when there is no modsettings file" do
      before do
        File.write("mod-data.json", "{}")

        allow(self).to receive(:puts)
        allow(self).to receive(:get_toml_config).and_return({})
        allow(self).to receive(:modsettings_dir).and_return(".")
      end

      it "raises an error that the file doesn't exist" do
        expect { refresh_cmd }.to raise_error(Errno::ENOENT)
      end
    end
  end
end
