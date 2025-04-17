# frozen_string_literal: true

require "pp"
require "fakefs/spec_helpers"
require "json"
require "date"

require_relative "../src/refresh_cmd"
require_relative "../src/helpers/modsettings_helper"
require_relative "../src/helpers/config_helper"
require_relative "../src/utils/volo"

RSpec.describe RefreshCmd do
  include FakeFS::SpecHelpers

  let(:logger) { spy }

  before do
    stub_const("ROOT_DIR", ".")

    File.write("mod-data.json", "{}")
    File.write("conf.toml", "")

    allow(Volo).to receive(:new).and_return(logger)
  end

  describe "#run" do
    let(:refresh_cmd) { RefreshCmd.new }
    let(:modsettings_helper) { ModsettingsHelper.new(config_helper, logger) }
    let(:config_helper) { ConfigHelper.new }

    before do
      allow(ModsettingsHelper).to receive(:new).and_return(modsettings_helper)
      allow(modsettings_helper).to receive(:modsettings_dir).and_return(".")
    end

    context "when there is nothing in the modsettings" do
      before do
        File.write("mod-data.json", "{}")
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
                      </children>
                    </node>
                  </children>
                </node>
              </region>
            </save>
          XML
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
        expect(logger).to receive(:error).with(/\ANo such file or directory/)

        refresh_cmd.run
      end
    end

    context "when there are 'gustav' entries" do
      before do
        File.write("mod-data.json", "{}")
        File.write(
          "modsettings.lsx",
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
                          <attribute id="Folder" type="LSString" value="GustavX"/>
                          <attribute id="MD5" type="LSString" value="180daa208a8a447d4ea7f6b4a47e93f1"/>
                          <attribute id="Name" type="LSString" value="GustavX"/>
                          <attribute id="PublishHandle" type="uint64" value="0"/>
                          <attribute id="UUID" type="guid" value="cb555efe-2d9e-131f-8195-a89329d218ea"/>
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

        refresh_cmd.run
      end

      it "skips any gustav entries" do
        expect(File.read("mod-data.json")).to eq("{}")
      end
    end

    context "when there are mods in the modsettings file" do
      before do
        File.write("mod-data.json", "{}")
        File.write(
          "modsettings.lsx",
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
          XML
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
        File.write(
          "modsettings.lsx",
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
          XML
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

    context "when there are some mods that are disabled in modsettings.lsx" do
      before do
        File.write("mod-data.json", {
          "97b49e95-5fa4-4912-b02d-ccf25ea176fe" => {
            "is_installed" => true,
            "mod_name" => "Disabled mod",
            "uuid" => "97b49e95-5fa4-4912-b02d-ccf25ea176fe",
            "number" => 1,
            "created_at" => Time.now.to_s,
            "updated_at" => Time.now.to_s
          }
        }.to_json)
        File.write(
          "modsettings.lsx",
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
                          <attribute id="Folder" type="LSString" value="Enabled mod"/>
                          <attribute id="MD5" type="LSString" value="3112eaf64d4fabdc282b079e8fe06fdc"/>
                          <attribute id="Name" type="LSString" value="Enabled mod"/>
                          <attribute id="PublishHandle" type="uint64" value=""/>
                          <attribute id="UUID" type="guid" value="03262688-5c2f-4259-9680-a050a1baf20e"/>
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

        refresh_cmd.run
      end

      it "adds the new enabled mod" do
        expect(JSON.parse(File.read("mod-data.json"))).to include({
          "03262688-5c2f-4259-9680-a050a1baf20e" => hash_including({
            "is_installed" => true,
            "mod_name" => "Enabled mod",
            "uuid" => "03262688-5c2f-4259-9680-a050a1baf20e",
            "number" => 2
          })
        })
      end

      it "disables the existing mod" do
        mod_data = JSON.parse(File.read("mod-data.json"))
        expect(mod_data).to include({
          "97b49e95-5fa4-4912-b02d-ccf25ea176fe" => hash_including({
            "is_installed" => false,
            "mod_name" => "Disabled mod",
            "uuid" => "97b49e95-5fa4-4912-b02d-ccf25ea176fe",
            "number" => 1
          })
        })
        expect(mod_data.keys.size).to eq(2)
      end
    end

    context "when there are some mods that are enabled in modsettings.lsx" do
      before do
        File.write("mod-data.json", {
          "79fb9cf3-6f30-45e8-8738-b0752734eaa5" => {
            "is_installed" => false,
            "mod_name" => "Should be enabled",
            "uuid" => "79fb9cf3-6f30-45e8-8738-b0752734eaa5",
            "number" => 1,
            "created_at" => Time.now.to_s,
            "updated_at" => Time.now.to_s
          }
        }.to_json)
        File.write(
          "modsettings.lsx",
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
                          <attribute id="Folder" type="LSString" value="Should be enabled"/>
                          <attribute id="MD5" type="LSString" value="3112eaf64d4fabdc282b079e8fe06fdc"/>
                          <attribute id="Name" type="LSString" value="Should be enabled"/>
                          <attribute id="PublishHandle" type="uint64" value=""/>
                          <attribute id="UUID" type="guid" value="79fb9cf3-6f30-45e8-8738-b0752734eaa5"/>
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

        refresh_cmd.run
      end

      it "sets the mod as enabled" do
        mod_data = JSON.parse(File.read("mod-data.json"))
        expect(mod_data).to include({
          "79fb9cf3-6f30-45e8-8738-b0752734eaa5" => hash_including({
            "is_installed" => true,
            "mod_name" => "Should be enabled",
            "uuid" => "79fb9cf3-6f30-45e8-8738-b0752734eaa5",
            "number" => 1
          })
        })
        expect(mod_data.keys.size).to eq(1)
      end
    end
  end
end
