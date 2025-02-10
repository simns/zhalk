require "pp"
require "fakefs/spec_helpers"
require "nokogiri"
require "json"
require "date"

require_relative "../src/update_cmd"
require_relative "../src/install_cmd"
require_relative "../src/helpers/modsettings_helper"
require_relative "../src/helpers/mod_data_helper"
require_relative "../src/helpers/config_helper"

RSpec.describe UpdateCmd do
  include FakeFS::SpecHelpers

  describe "#run" do
    let(:update_cmd) { UpdateCmd.new }
    let(:install_cmd) { InstallCmd.new }
    let(:mod_data_helper) { ModDataHelper.new }
    let(:modsettings_helper) { ModsettingsHelper.new(config_helper) }
    let(:config_helper) { ConfigHelper.new }

    before do
      File.write("conf.toml",
                 <<-CONF
[paths]
appdata_dir = "appdata"
steam_dir = "steam"
CONF
      )
      FileUtils.mkdir_p(File.join("appdata", "PlayerProfiles", "Public"))
      FileUtils.mkdir_p(File.join("appdata", "Mods"))

      FileUtils.mkdir("mods")
      FileUtils.mkdir("dump")

      allow(ModDataHelper).to receive(:new).and_return(mod_data_helper)
      allow(mod_data_helper).to receive(:puts)
      allow(ModsettingsHelper).to receive(:new).and_return(modsettings_helper)
      allow(modsettings_helper).to receive(:puts)

      allow(update_cmd).to receive(:puts)
    end

    context "when there is one mod to be updated" do
      before do
        File.write("mod-data.json", {
          "1df98992-ee83-4d46-9b2d-be8f0ff805f8" => {
            "is_installed" => true,
            "mod_name" => "Mod 1",
            "uuid" => "1df98992-ee83-4d46-9b2d-be8f0ff805f8",
            "number" => 1,
            "created_at" => Time.now.to_s,
            "updated_at" => Time.now.to_s
          }
        })

        File.write(File.join("appdata", "PlayerProfiles", "Public", "modsettings.lsx"),
                   <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<save>
  <version major="4" minor="7" revision="1" build="300"/>
  <region id="ModuleSettings">
    <node id="root">
      <children>
        <node id="Mods">
          <children>
            <node id="ModuleShortDesc">
              <attribute id="Folder" type="LSString" value="GustavDev"/>
              <attribute id="MD5" type="LSString" value=""/>
              <attribute id="Name" type="LSString" value="GustavDev"/>
              <attribute id="PublishHandle" type="uint64" value="0"/>
              <attribute id="UUID" type="guid" value="28ac9ce2-2aba-8cda-b3b5-6e922f71b6b8"/>
              <attribute id="Version64" type="int64" value="36028797018963968"/>
            </node>
            <node id="ModuleShortDesc">
              <attribute id="Folder" type="LSString" value="Mod 1"/>
              <attribute id="MD5" type="LSString" value="ee8a3210df51af3cea80ed82d2d99118"/>
              <attribute id="Name" type="LSString" value="Mod 1"/>
              <attribute id="UUID" type="guid" value="1df98992-ee83-4d46-9b2d-be8f0ff805f8"/>
              <attribute id="Version64" type="int64" value=""/>
            </node>
          </children>
        </node>
      </children>
    </node>
  </region>
</save>
XML
        )

        File.write(File.join("appdata", "Mods", "mod1.pak"), "old pak")

        FileUtils.touch(File.join("mods", "mod1.zip"))

        allow(install_cmd).to receive(:extract_mod_files) do
          FileUtils.mkdir_p(File.join("dump", "mod1"))
          FileUtils.write(File.join("dump", "mod1", "mod1.pak"), "new pak")
          File.write(File.join("dump", "mod1", "info.json"), {
            "Mods": [
              {
                "Author": "Poopie",
                "Name": "Mod 1",
                "Folder": "Mod 1",
                "Version": "",
                "Description": "Mod 1 description",
                "UUID": "1df98992-ee83-4d46-9b2d-be8f0ff805f8",
                "Created": "2024-01-01T03:00:00.1238948+09:00",
                "Dependencies": [],
                "Group": "8f6b4ca9-61fa-44cd-a7dd-f75c1be9febc"
              }
            ],
            "MD5": "ee8a3210df51af3cea80ed82d2d99118"
          }.to_json)
        end
      end

      it "asdf" do
        expect()
        update_cmd.run
      end
    end
  end
end
