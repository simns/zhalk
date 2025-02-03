require "pp"
require "fakefs/spec_helpers"
require "json"
require "date"

require_relative "../src/refresh_cmd"
require_relative "../src/helpers/modsettings_helper"
require_relative "../src/helpers/config_helper"

RSpec.describe RefreshCmd do
  include FakeFS::SpecHelpers

  before do
    File.write("mod-data.json", "{}")
    File.write("conf.toml", "")
  end

  describe "#run" do
    let(:refresh_cmd) { RefreshCmd.new }
    let(:modsettings_helper) { ModsettingsHelper.new(config_helper) }
    let(:config_helper) { ConfigHelper.new }

    before do
      allow(ModsettingsHelper).to receive(:new).and_return(modsettings_helper)
      allow(modsettings_helper).to receive(:modsettings_dir).and_return(".")
      allow(modsettings_helper).to receive(:puts)
      allow(refresh_cmd).to receive(:puts)
    end

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

        refresh_cmd.run
      end

      it "doesn't add anything to mod-data.json" do
        expect(File.read("mod-data.json")).to eq("{}")
      end
    end

    context "when there is no modsettings file" do
      before do
        File.write("mod-data.json", "{}")
      end

      it "raises an error that the file doesn't exist" do
        expect { refresh_cmd.run }.to raise_error(Errno::ENOENT)
      end
    end

    context "when there are mods in the modsettings file" do
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
            <node id="ModuleShortDesc">
              <attribute id="Folder" type="LSString" value="Mod to refresh"/>
              <attribute id="MD5" type="LSString" value="37f141617cf2f6303442a5ef27a78ecc"/>
              <attribute id="Name" type="LSString" value="Mod to refresh"/>
              <attribute id="PublishHandle" type="uint64" value=""/>
              <attribute id="UUID" type="guid" value="02a0bea9-a631-4c45-9ffe-5876bb133967"/>
              <attribute id="Version64" type="int64" value=""/>
            </node>
          </children>
        </node>
      </children>
    </node>
  </region>
</save>
MODSETTINGS
        )

        refresh_cmd.run
      end

      it "reads the mod into mod-data.json" do
        mod_data = JSON.parse(File.read("mod-data.json"))
        expect(mod_data).to include({
          "02a0bea9-a631-4c45-9ffe-5876bb133967" => hash_including({
            "is_installed" => true,
            "mod_name" => "Mod to refresh",
            "uuid" => "02a0bea9-a631-4c45-9ffe-5876bb133967",
            "number" => 1
          })
        })
        expect(mod_data.keys.size).to eq(1)
      end
    end

    context "when trying to read mods that are already installed" do
      before do
        File.write("mod-data.json", {
          "1a5432e9-7821-4ef7-a66f-8cf3a11d45f9" => {
            "is_installed" => true,
            "mod_name" => "Existing mod",
            "uuid" => "1a5432e9-7821-4ef7-a66f-8cf3a11d45f9",
            "number" => 1,
            "created_at" => Time.now.to_s,
            "updated_at" => Time.now.to_s
          }
        }.to_json)
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
            <node id="ModuleShortDesc">
              <attribute id="Folder" type="LSString" value="Existing mod"/>
              <attribute id="MD5" type="LSString" value="3112eaf64d4fabdc282b079e8fe06fdc"/>
              <attribute id="Name" type="LSString" value="Existing mod"/>
              <attribute id="PublishHandle" type="uint64" value=""/>
              <attribute id="UUID" type="guid" value="1a5432e9-7821-4ef7-a66f-8cf3a11d45f9"/>
              <attribute id="Version64" type="int64" value=""/>
            </node>
          </children>
        </node>
      </children>
    </node>
  </region>
</save>
MODSETTINGS
        )

        refresh_cmd.run
      end

      it "skips the mod that is already installed" do
        mod_data = JSON.parse(File.read("mod-data.json"))
        expect(mod_data).to include({
          "1a5432e9-7821-4ef7-a66f-8cf3a11d45f9" => hash_including({
            "is_installed" => true,
            "mod_name" => "Existing mod",
            "uuid" => "1a5432e9-7821-4ef7-a66f-8cf3a11d45f9",
            "number" => 1
          })
        })
        expect(mod_data.keys.size).to eq(1)
      end
    end
  end
end
