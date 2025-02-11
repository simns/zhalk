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
      allow(InstallCmd).to receive(:new).and_return(install_cmd)

      allow(install_cmd).to receive(:puts)
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
        }.to_json)

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
          File.write(File.join("dump", "mod1", "mod1.pak"), "new pak")
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

      it "does not modify modsettings" do
        expect(install_cmd).to receive(:extract_mod_files)
        expect(install_cmd).to_not receive(:insert_into_modsettings)
        expect(install_cmd).to receive(:update_mod_data)
        expect(install_cmd).to receive(:copy_pak_files)

        update_cmd.run
      end

      it "updates the 'updated_at' field in mod-data.json" do
        expect(mod_data_helper).to receive(:set_updated)

        update_cmd.run
      end

      it "copies and overwrites the pak files" do
        update_cmd.run

        expect(File.read(File.join("appdata", "Mods", "mod1.pak"))).to eq("new pak")
      end
    end

    context "when there are deactivated mods" do
      before do
        File.write("mod-data.json", {
          "1afc5d5b-f48a-4509-9b56-b30da60dc23d" => {
            "is_installed" => true,
            "mod_name" => "Mod 1",
            "uuid" => "1afc5d5b-f48a-4509-9b56-b30da60dc23d",
            "number" => 1,
            "created_at" => Time.now.to_s,
            "updated_at" => Time.now.to_s
          },
          "21fb928e-8b9a-404e-9580-dd3bbf16284b" => {
            "is_installed" => false,
            "mod_name" => "Mod 2",
            "uuid" => "21fb928e-8b9a-404e-9580-dd3bbf16284b",
            "number" => 2,
            "created_at" => Time.now.to_s,
            "updated_at" => Time.now.to_s
          }
        }.to_json)

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
              <attribute id="UUID" type="guid" value="1afc5d5b-f48a-4509-9b56-b30da60dc23d"/>
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
        File.write(File.join("appdata", "Mods", "mod2.pak"), "old pak2")

        FileUtils.touch(File.join("mods", "mod1.zip"))
        FileUtils.touch(File.join("mods", "mod2.zip"))

        allow(install_cmd).to receive(:extract_mod_files) do
          FileUtils.mkdir_p(File.join("dump", "mod1"))
          File.write(File.join("dump", "mod1", "mod1.pak"), "new pak")
          File.write(File.join("dump", "mod1", "info.json"), {
            "Mods": [
              {
                "Author": "Poopie",
                "Name": "Mod 1",
                "Folder": "Mod 1",
                "Version": "",
                "Description": "Mod 1 description",
                "UUID": "1afc5d5b-f48a-4509-9b56-b30da60dc23d",
                "Created": "2024-01-01T03:00:00.1238948+09:00",
                "Dependencies": [],
                "Group": "8f6b4ca9-61fa-44cd-a7dd-f75c1be9febc"
              }
            ],
            "MD5": "ee8a3210df51af3cea80ed82d2d99118"
          }.to_json)

          FileUtils.mkdir_p(File.join("dump", "mod2"))
          File.write(File.join("dump", "mod2", "mod2.pak"), "new pak2")
          File.write(File.join("dump", "mod2", "info.json"), {
            "Mods": [
              {
                "Author": "Poopie",
                "Name": "Mod 2",
                "Folder": "Mod 2",
                "Version": "",
                "Description": "Mod 2 description",
                "UUID": "21fb928e-8b9a-404e-9580-dd3bbf16284b",
                "Created": "2024-01-01T03:00:00.1238948+09:00",
                "Dependencies": [],
                "Group": "8f6b4ca9-61fa-44cd-a7dd-f75c1be9febc"
              }
            ],
            "MD5": "ee8a3210df51af3cea80ed82d2d99118"
          }.to_json)
        end
      end

      it "does not modify modsettings" do
        expect(install_cmd).to receive(:extract_mod_files)
        expect(install_cmd).to_not receive(:insert_into_modsettings)
        expect(install_cmd).to receive(:update_mod_data).twice
        expect(install_cmd).to receive(:copy_pak_files).twice

        update_cmd.run

        expect(File.read(File.join(
          "appdata",
          "PlayerProfiles",
          "Public",
          "modsettings.lsx"
        ))).to eq(
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
              <attribute id="UUID" type="guid" value="1afc5d5b-f48a-4509-9b56-b30da60dc23d"/>
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
      end

      it "updates the 'updated_at' field in mod-data.json for the active mod only" do
        expect(mod_data_helper).to receive(:set_updated).with("1afc5d5b-f48a-4509-9b56-b30da60dc23d")
        expect(mod_data_helper).to_not receive(:set_updated).with("21fb928e-8b9a-404e-9580-dd3bbf16284b")

        update_cmd.run
      end

      it "does not reactivate any deactivated mods" do
        update_cmd.run

        expect(JSON.parse(File.read("mod-data.json"))).to include({
          "1afc5d5b-f48a-4509-9b56-b30da60dc23d" => hash_including({
            "is_installed" => true,
            "mod_name" => "Mod 1",
            "uuid" => "1afc5d5b-f48a-4509-9b56-b30da60dc23d",
            "number" => 1
          }),
          "21fb928e-8b9a-404e-9580-dd3bbf16284b" => hash_including({
            "is_installed" => false,
            "mod_name" => "Mod 2",
            "uuid" => "21fb928e-8b9a-404e-9580-dd3bbf16284b",
            "number" => 2
          })
        })
      end

      it "copies and overwrites the pak files for all mods" do
        update_cmd.run

        expect(File.read(File.join("appdata", "Mods", "mod1.pak"))).to eq("new pak")
        expect(File.read(File.join("appdata", "Mods", "mod2.pak"))).to eq("new pak2")
      end
    end

    context "when there are uninstalled mods" do
      before do
        File.write("mod-data.json", {
          "50b0407d-bc9f-4cac-a663-505f33fa7a54" => {
            "is_installed" => true,
            "mod_name" => "Mod 1",
            "uuid" => "50b0407d-bc9f-4cac-a663-505f33fa7a54",
            "number" => 1,
            "created_at" => Time.now.to_s,
            "updated_at" => Time.now.to_s
          }
        }.to_json)

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
              <attribute id="UUID" type="guid" value="50b0407d-bc9f-4cac-a663-505f33fa7a54"/>
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
        File.write(File.join("appdata", "Mods", "mod2.pak"), "old pak2")

        FileUtils.touch(File.join("mods", "mod1.zip"))
        FileUtils.touch(File.join("mods", "mod2.zip"))

        allow(install_cmd).to receive(:extract_mod_files) do
          FileUtils.mkdir_p(File.join("dump", "mod1"))
          File.write(File.join("dump", "mod1", "mod1.pak"), "new pak")
          File.write(File.join("dump", "mod1", "info.json"), {
            "Mods": [
              {
                "Author": "Poopie",
                "Name": "Mod 1",
                "Folder": "Mod 1",
                "Version": "",
                "Description": "Mod 1 description",
                "UUID": "50b0407d-bc9f-4cac-a663-505f33fa7a54",
                "Created": "2024-01-01T03:00:00.1238948+09:00",
                "Dependencies": [],
                "Group": "8f6b4ca9-61fa-44cd-a7dd-f75c1be9febc"
              }
            ],
            "MD5": "ee8a3210df51af3cea80ed82d2d99118"
          }.to_json)

          FileUtils.mkdir_p(File.join("dump", "mod2"))
          File.write(File.join("dump", "mod2", "mod2.pak"), "new pak2")
          File.write(File.join("dump", "mod2", "info.json"), {
            "Mods": [
              {
                "Author": "Poopie",
                "Name": "Mod 2",
                "Folder": "Mod 2",
                "Version": "",
                "Description": "Mod 2 description",
                "UUID": "81381cfe-41fe-4962-a4c1-22390bbba4af",
                "Created": "2024-01-01T03:00:00.1238948+09:00",
                "Dependencies": [],
                "Group": "8f6b4ca9-61fa-44cd-a7dd-f75c1be9febc"
              }
            ],
            "MD5": "ee8a3210df51af3cea80ed82d2d99118"
          }.to_json)
        end
      end

      it "does not modify modsettings" do
        expect(install_cmd).to receive(:extract_mod_files)
        expect(install_cmd).to_not receive(:insert_into_modsettings)
        expect(install_cmd).to receive(:update_mod_data).twice
        expect(install_cmd).to receive(:copy_pak_files).twice

        update_cmd.run

        expect(File.read(File.join(
          "appdata",
          "PlayerProfiles",
          "Public",
          "modsettings.lsx"
        ))).to eq(
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
              <attribute id="UUID" type="guid" value="50b0407d-bc9f-4cac-a663-505f33fa7a54"/>
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
      end

      it "updates the 'updated_at' field in mod-data.json for the active mod only" do
        expect(mod_data_helper).to receive(:set_updated).with("50b0407d-bc9f-4cac-a663-505f33fa7a54")
        expect(mod_data_helper).to_not receive(:set_updated).with("81381cfe-41fe-4962-a4c1-22390bbba4af")

        update_cmd.run
      end

      it "does not install uninstalled mods" do
        update_cmd.run

        mod_data = JSON.parse(File.read("mod-data.json"))
        expect(mod_data).to include({
          "50b0407d-bc9f-4cac-a663-505f33fa7a54" => hash_including({
            "is_installed" => true,
            "mod_name" => "Mod 1",
            "uuid" => "50b0407d-bc9f-4cac-a663-505f33fa7a54",
            "number" => 1
          })
        })
        expect(mod_data.keys.size).to eq(1)
      end

      it "copies and overwrites the pak files for all mods" do
        update_cmd.run

        expect(File.read(File.join("appdata", "Mods", "mod1.pak"))).to eq("new pak")
        expect(File.read(File.join("appdata", "Mods", "mod2.pak"))).to eq("new pak2")
      end
    end
  end
end
