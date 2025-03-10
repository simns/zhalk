# frozen_string_literal: true

require "pp"
require "fakefs/spec_helpers"
require "nokogiri"
require "json"
require "date"

require_relative "../src/install_cmd"
require_relative "../src/helpers/modsettings_helper"
require_relative "../src/helpers/config_helper"
require_relative "../src/helpers/info_json_helper"
require_relative "../src/utils/volo"

RSpec.describe InstallCmd do
  include FakeFS::SpecHelpers

  let(:logger) { spy }

  before do
    stub_const("ROOT_DIR", ".")

    allow(Volo).to receive(:new).and_return(logger)
  end

  describe "#insert_into_modsettings" do
    let(:install_cmd) { InstallCmd.new }
    let(:modsettings_helper) { ModsettingsHelper.new(config_helper, logger) }
    let(:config_helper) { ConfigHelper.new }

    before do
      allow(ModsettingsHelper).to receive(:new).and_return(modsettings_helper)
      allow(modsettings_helper).to receive(:modsettings_dir).and_return(".")
    end

    context "when there aren't existing mods" do
      let(:info_json_helper) do
        instance_double(InfoJsonHelper,
          folder: "Test Folder",
          md5: "54c3136171518f973ad518b43f3f35ae",
          name: "Test Mod",
          uuid: "658ba936-8a5c-40f1-94a6-7bf8d874b66e",
          version: "")
      end

      before do
        File.write("modsettings.lsx",
          <<~XML
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
                      </children>
                    </node>
                  </children>
                </node>
              </region>
            </save>
          XML
        )

        install_cmd.insert_into_modsettings(info_json_helper)
      end

      it "adds the mod to modsettings.lsx" do
        expect(File.read("modsettings.lsx")).to eq(
          <<~XML
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
                          <attribute id="Folder" type="LSString" value="Test Folder"/>
                          <attribute id="MD5" type="LSString" value="54c3136171518f973ad518b43f3f35ae"/>
                          <attribute id="Name" type="LSString" value="Test Mod"/>
                          <attribute id="UUID" type="guid" value="658ba936-8a5c-40f1-94a6-7bf8d874b66e"/>
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
    end

    context "when the target mod is already present" do
      let(:info_json_helper) do
        instance_double(InfoJsonHelper,
          folder: "Test Folder",
          md5: "54c3136171518f973ad518b43f3f35ae",
          name: "Test Mod",
          uuid: "cf5175fb-0a7c-4af3-b51c-14b683a5cb7d",
          version: "")
      end

      before do
        File.write("modsettings.lsx",
          <<~XML
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
                          <attribute id="Folder" type="LSString" value="Test Folder"/>
                          <attribute id="MD5" type="LSString" value="54c3136171518f973ad518b43f3f35ae"/>
                          <attribute id="Name" type="LSString" value="Test Mod"/>
                          <attribute id="UUID" type="guid" value="cf5175fb-0a7c-4af3-b51c-14b683a5cb7d"/>
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

      it "doesn't modify anything" do
        install_cmd.insert_into_modsettings(info_json_helper)

        expect(File.read("modsettings.lsx")).to eq(
          <<~XML
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
                          <attribute id="Folder" type="LSString" value="Test Folder"/>
                          <attribute id="MD5" type="LSString" value="54c3136171518f973ad518b43f3f35ae"/>
                          <attribute id="Name" type="LSString" value="Test Mod"/>
                          <attribute id="UUID" type="guid" value="cf5175fb-0a7c-4af3-b51c-14b683a5cb7d"/>
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
    end
  end

  describe "#update_mod_data" do
    let(:install_cmd) { InstallCmd.new }

    context "when mod-data.json is empty" do
      let(:info_json_helper) do
        instance_double(
          InfoJsonHelper,
          name: "Test Mod",
          uuid: "6df04e78-79ba-4c56-aa68-67e843f78ac9"
        )
      end

      before do
        File.write("mod-data.json", "{}")

        install_cmd.update_mod_data(info_json_helper)
      end

      it "saves to mod-data.json" do
        mod_data = JSON.parse(File.read("mod-data.json"))
        expect(mod_data).to include({
          "6df04e78-79ba-4c56-aa68-67e843f78ac9" => hash_including({
            "is_installed" => true,
            "mod_name" => "Test Mod",
            "uuid" => "6df04e78-79ba-4c56-aa68-67e843f78ac9",
            "number" => 1
          })
        })
        expect(mod_data.keys.size).to eq(1)
      end
    end

    context "when mod-data.json has the target entry as uninstalled" do
      let(:info_json_helper) do
        instance_double(
          InfoJsonHelper,
          name: "Test Mod",
          uuid: "18f35d9d-aaaa-4df6-8d3e-c2cdc5ae0c1b"
        )
      end

      before do
        File.write("mod-data.json", {
          "18f35d9d-aaaa-4df6-8d3e-c2cdc5ae0c1b" => {
            "is_installed" => false,
            "mod_name" => "Test Mod",
            "uuid" => "18f35d9d-aaaa-4df6-8d3e-c2cdc5ae0c1b",
            "number" => 1,
            "created_at" => Time.now.to_s,
            "updated_at" => Time.now.to_s
          }
        }.to_json)

        install_cmd.update_mod_data(info_json_helper)
      end

      it "ignores the uninstalled entry" do
        mod_data = JSON.parse(File.read("mod-data.json"))
        expect(mod_data).to include({
          "18f35d9d-aaaa-4df6-8d3e-c2cdc5ae0c1b" => hash_including({
            "is_installed" => false,
            "mod_name" => "Test Mod",
            "uuid" => "18f35d9d-aaaa-4df6-8d3e-c2cdc5ae0c1b",
            "number" => 1
          })
        })
        expect(mod_data.keys.size).to eq(1)
      end
    end
  end

  describe "#run" do
    let(:install_cmd) { InstallCmd.new }
    let(:config_helper) { ConfigHelper.new }

    before do
      File.write("mod-data.json", "{}")
      File.write("conf.toml",
        <<~CONF
          [paths]
          appdata_dir = "appdata"
        CONF
      )
      FileUtils.mkdir_p(File.join("appdata", "PlayerProfiles", "Public"))
      FileUtils.mkdir_p(File.join("appdata", "Mods"))
      File.write(File.join("appdata", "PlayerProfiles", "Public", "modsettings.lsx"),
        <<~XML
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
                    </children>
                  </node>
                </children>
              </node>
            </region>
          </save>
        XML
      )
      FileUtils.mkdir("mods")
      FileUtils.mkdir("dump")
    end

    context "when all necessary files exist" do
      it "creates a backup of modsettings" do
        install_cmd.run

        expect(File.exist?(File.join(
          "appdata",
          "PlayerProfiles",
          "Public",
          "modsettings.lsx.bak"
        ))).to be(true)
      end

      context "when there are mods in the 'mods' folder" do
        before do
          FileUtils.touch(File.join("mods", "mod1.zip"))

          allow(install_cmd).to receive(:extract_mod_files) do
            FileUtils.mkdir_p(File.join("dump", "mod1"))
            FileUtils.touch(File.join("dump", "mod1", "mod1.pak"))
            File.write(File.join("dump", "mod1", "info.json"), {
              "Mods": [
                {
                  "Author": "Poopie",
                  "Name": "Mod 1",
                  "Folder": "Mod 1",
                  "Version": "",
                  "Description": "Mod 1 description",
                  "UUID": "ce0be3e5-d6c4-4ace-a649-88d1dfdc23ab",
                  "Created": "2024-01-01T03:00:00.1238948+09:00",
                  "Dependencies": [],
                  "Group": "6f19e75b-fb4d-47a5-ae60-1a54726f44ba"
                }
              ],
              "MD5": "ee8a3210df51af3cea80ed82d2d99118"
            }.to_json)
          end

          install_cmd.run
        end

        it "updates modsettings.lsx" do
          expect(
            File.read(File.join("appdata", "PlayerProfiles", "Public", "modsettings.lsx"))
          ).to eq(
            <<~XML
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
                            <attribute id="UUID" type="guid" value="ce0be3e5-d6c4-4ace-a649-88d1dfdc23ab"/>
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

        it "adds the mod to mod-data.json" do
          mod_data = JSON.parse(File.read("mod-data.json"))
          expect(mod_data).to include({
            "ce0be3e5-d6c4-4ace-a649-88d1dfdc23ab" => hash_including({
              "is_installed" => true,
              "mod_name" => "Mod 1",
              "uuid" => "ce0be3e5-d6c4-4ace-a649-88d1dfdc23ab",
              "number" => 1
            })
          })
          expect(mod_data.keys.size).to eq(1)
        end

        it "moves the pak files" do
          expect(File.exist?(File.join("appdata", "Mods", "mod1.pak"))).to be(true)
        end
      end

      context "when the mod is already set as installed" do
        before do
          FileUtils.touch(File.join("mods", "mod1.zip"))
          FileUtils.mkdir(File.join("dump", "mod1"))
          FileUtils.touch(File.join("dump", "mod1", "mod1.pak"))
          File.write(File.join("dump", "mod1", "info.json"), {
            "Mods": [
              {
                "Author": "Poopie",
                "Name": "Mod 1",
                "Folder": "Mod 1",
                "Version": "",
                "Description": "Mod 1 description",
                "UUID": "a3455a30-0225-4a5e-9bab-90899aba9fab",
                "Created": "2024-01-01T03:00:00.1238948+09:00",
                "Dependencies": [],
                "Group": "6f19e75b-fb4d-47a5-ae60-1a54726f44ba"
              }
            ],
            "MD5": "ee8a3210df51af3cea80ed82d2d99118"
          }.to_json)

          File.write("mod-data.json", {
            "a3455a30-0225-4a5e-9bab-90899aba9fab" => {
              "is_installed" => true,
              "mod_name" => "Mod 1",
              "uuid" => "a3455a30-0225-4a5e-9bab-90899aba9fab",
              "number" => 1,
              "created_at" => Time.now.to_s,
              "updated_at" => Time.now.to_s
            }
          }.to_json)
        end

        it "skips the installation" do
          expect(install_cmd).to receive(:extract_mod_files)
          expect(install_cmd).to_not receive(:insert_into_modsettings)
          expect(install_cmd).to_not receive(:update_mod_data)

          install_cmd.run
        end
      end

      context "when the mod is set as inactive" do
        before do
          FileUtils.touch(File.join("mods", "mod1.zip"))
          FileUtils.mkdir(File.join("dump", "mod1"))
          FileUtils.touch(File.join("dump", "mod1", "mod1.pak"))
          File.write(File.join("dump", "mod1", "info.json"), {
            "Mods": [
              {
                "Author": "Poopie",
                "Name": "Mod 1",
                "Folder": "Mod 1",
                "Version": "",
                "Description": "Mod 1 description",
                "UUID": "cc45e136-ae1e-4118-83f8-6e11a04beee3",
                "Created": "2024-01-01T03:00:00.1238948+09:00",
                "Dependencies": [],
                "Group": "6f19e75b-fb4d-47a5-ae60-1a54726f44ba"
              }
            ],
            "MD5": "ee8a3210df51af3cea80ed82d2d99118"
          }.to_json)

          File.write("mod-data.json", {
            "cc45e136-ae1e-4118-83f8-6e11a04beee3" => {
              "is_installed" => false,
              "mod_name" => "Mod 1",
              "uuid" => "cc45e136-ae1e-4118-83f8-6e11a04beee3",
              "number" => 1,
              "created_at" => Time.now.to_s,
              "updated_at" => Time.now.to_s
            }
          }.to_json)
        end

        it "skips the installation" do
          expect(install_cmd).to receive(:extract_mod_files)
          expect(install_cmd).to_not receive(:insert_into_modsettings)
          expect(install_cmd).to_not receive(:update_mod_data)

          install_cmd.run
        end
      end
    end
  end
end
