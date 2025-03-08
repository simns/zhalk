# frozen_string_literal: true

require "pp"
require "fakefs/spec_helpers"
require "json"
require "date"

require_relative "../src/activate_cmd"
require_relative "../src/helpers/modsettings_helper"
require_relative "../src/helpers/config_helper"
require_relative "../src/helpers/constants"
require_relative "../src/utils/volo"

RSpec.describe ActivateCmd do
  include FakeFS::SpecHelpers

  let(:logger) { spy }

  before do
    stub_const("ROOT_DIR", ".")

    allow(Volo).to receive(:new).and_return(logger)
  end

  describe "#run" do
    let(:activate_cmd) { ActivateCmd.new }
    let(:modsettings_helper) { ModsettingsHelper.new(config_helper, logger) }
    let(:config_helper) { ConfigHelper.new }

    before do
      allow(ModsettingsHelper).to receive(:new).and_return(modsettings_helper)
      allow(modsettings_helper).to receive(:modsettings_dir).and_return(".")

      FileUtils.mkdir(Constants::INACTIVE_DIR)

      File.write("conf.toml", "")
    end

    context "when the target mod exists" do
      before do
        File.write("mod-data.json", {
          "ad2a6207-4fbe-4e80-ba6e-e0b148367e7b" => {
            "is_installed" => false,
            "mod_name" => "Test Mod",
            "uuid" => "ad2a6207-4fbe-4e80-ba6e-e0b148367e7b",
            "number" => 1,
            "created_at" => Time.now.to_s,
            "updated_at" => Time.now.to_s
          }
        }.to_json)
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
        File.write(File.join(Constants::INACTIVE_DIR, "ad2a6207-4fbe-4e80-ba6e-e0b148367e7b.xml"),
          <<~XML
            <node id="ModuleShortDesc">
              <attribute id="Folder" type="LSString" value="Test Folder"/>
              <attribute id="MD5" type="LSString" value="54c3136171518f973ad518b43f3f35ae"/>
              <attribute id="Name" type="LSString" value="Test Mod"/>
              <attribute id="UUID" type="guid" value="ad2a6207-4fbe-4e80-ba6e-e0b148367e7b"/>
              <attribute id="Version64" type="int64" value=""/>
            </node>
          XML
        )

        activate_cmd.run("1")
      end

      it "adds the mod back to modsettings" do
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
                          <attribute id="UUID" type="guid" value="ad2a6207-4fbe-4e80-ba6e-e0b148367e7b"/>
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

      it "does not delete the backup xml file" do
        expect(File.read(File.join(
          Constants::INACTIVE_DIR,
          "ad2a6207-4fbe-4e80-ba6e-e0b148367e7b.xml"
        ))).to eq(
                           <<~XML
                             <node id="ModuleShortDesc">
                               <attribute id="Folder" type="LSString" value="Test Folder"/>
                               <attribute id="MD5" type="LSString" value="54c3136171518f973ad518b43f3f35ae"/>
                               <attribute id="Name" type="LSString" value="Test Mod"/>
                               <attribute id="UUID" type="guid" value="ad2a6207-4fbe-4e80-ba6e-e0b148367e7b"/>
                               <attribute id="Version64" type="int64" value=""/>
                             </node>
                           XML
                         )
      end

      it "sets the mod as installed in mod-data.json" do
        expect(JSON.parse(File.read("mod-data.json"))).to include({
          "ad2a6207-4fbe-4e80-ba6e-e0b148367e7b" => hash_including({
            "is_installed" => true,
            "mod_name" => "Test Mod",
            "uuid" => "ad2a6207-4fbe-4e80-ba6e-e0b148367e7b",
            "number" => 1
          })
        })
      end
    end

    context "when the inactive mod's backup xml cannot be found" do
      before do
        File.write("mod-data.json", {
          "f9e8c1a5-0932-4c99-89c4-a24ea6d9c160" => {
            "is_installed" => false,
            "mod_name" => "Test Mod",
            "uuid" => "f9e8c1a5-0932-4c99-89c4-a24ea6d9c160",
            "number" => 1,
            "created_at" => Time.now.to_s,
            "updated_at" => Time.now.to_s
          }
        }.to_json)
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
      end

      it "raises an error before any activation is performed" do
        expect(logger).to receive(:error).with("Could not find inactive mod's backup xml file.")

        activate_cmd.run("1")

        expect(JSON.parse(File.read("mod-data.json"))).to include({
          "f9e8c1a5-0932-4c99-89c4-a24ea6d9c160" => hash_including({
            "is_installed" => false,
            "mod_name" => "Test Mod",
            "uuid" => "f9e8c1a5-0932-4c99-89c4-a24ea6d9c160",
            "number" => 1
          })
        })

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

    context "when the target mod number cannot be found in mod-data.json" do
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
                          <attribute id="UUID" type="guid" value="4e1e3644-4b8d-4b22-8f41-1df688906309"/>
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

      it "prints that the mod number cannot be found" do
        expect(logger).to receive(:error).with("Could not find a mod with number: 1.")

        activate_cmd.run("1")
      end

      it "does not modify anything" do
        activate_cmd.run("1")

        expect(File.read("mod-data.json")).to eq("{}")
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
                          <attribute id="UUID" type="guid" value="4e1e3644-4b8d-4b22-8f41-1df688906309"/>
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

    context "when the inactive mod's backup xml has invalid data" do
      before do
        File.write("mod-data.json", {
          "dbc9693e-2448-42b0-8688-722a0ae285cc" => {
            "is_installed" => false,
            "mod_name" => "Test Mod",
            "uuid" => "dbc9693e-2448-42b0-8688-722a0ae285cc",
            "number" => 1,
            "created_at" => Time.now.to_s,
            "updated_at" => Time.now.to_s
          }
        }.to_json)
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

        File.write(File.join(Constants::INACTIVE_DIR, "dbc9693e-2448-42b0-8688-722a0ae285cc.xml"),
          <<~XML
            <node id="IncorrectIDOhNo">
              <attribute id="Folder" type="LSString" value="Test Folder"/>
              <attribute id="MD5" type="LSString" value="54c3136171518f973ad518b43f3f35ae"/>
              <attribute id="Name" type="LSString" value="Test Mod"/>
              <attribute id="UUID" type="guid" value="ad2a6207-4fbe-4e80-ba6e-e0b148367e7b"/>
              <attribute id="Version64" type="int64" value=""/>
            </node>
          XML
        )
      end

      it "raises an error before any activation is performed" do
        expect(logger).to receive(:error).with(
          "Could not find inactive mod entry in the backup file."
        )

        activate_cmd.run("1")

        expect(JSON.parse(File.read("mod-data.json"))).to include({
          "dbc9693e-2448-42b0-8688-722a0ae285cc" => hash_including({
            "is_installed" => false,
            "mod_name" => "Test Mod",
            "uuid" => "dbc9693e-2448-42b0-8688-722a0ae285cc",
            "number" => 1
          })
        })

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

    context "when the target mod is already active" do
      before do
        File.write("mod-data.json", {
          "c9aaa5a9-5ac4-40a5-a4b7-88fc5b94aa80" => {
            "is_installed" => true,
            "mod_name" => "Test Mod",
            "uuid" => "c9aaa5a9-5ac4-40a5-a4b7-88fc5b94aa80",
            "number" => 1,
            "created_at" => Time.now.to_s,
            "updated_at" => Time.now.to_s
          }
        }.to_json)
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
                          <attribute id="UUID" type="guid" value="c9aaa5a9-5ac4-40a5-a4b7-88fc5b94aa80"/>
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

      it "prints that the target mod is already deactivated" do
        expect(logger).to receive(:info).with("Target mod is already active.")

        activate_cmd.run("1")
      end

      it "does not modify anything" do
        activate_cmd.run("1")

        expect(JSON.parse(File.read("mod-data.json"))).to include({
          "c9aaa5a9-5ac4-40a5-a4b7-88fc5b94aa80" => hash_including({
            "is_installed" => true,
            "mod_name" => "Test Mod",
            "uuid" => "c9aaa5a9-5ac4-40a5-a4b7-88fc5b94aa80",
            "number" => 1
          })
        })

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
                          <attribute id="UUID" type="guid" value="c9aaa5a9-5ac4-40a5-a4b7-88fc5b94aa80"/>
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

    context "when the target mod has its entry in modsettings already" do
      before do
        File.write("mod-data.json", {
          "695d36a1-a0b2-4c36-a00d-060ebd8b1645" => {
            "is_installed" => false,
            "mod_name" => "Test Mod",
            "uuid" => "695d36a1-a0b2-4c36-a00d-060ebd8b1645",
            "number" => 1,
            "created_at" => Time.now.to_s,
            "updated_at" => Time.now.to_s
          }
        }.to_json)
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
                          <attribute id="UUID" type="guid" value="695d36a1-a0b2-4c36-a00d-060ebd8b1645"/>
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

        activate_cmd.run("1")
      end

      it "does not update modsettings.lsx" do
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
                          <attribute id="UUID" type="guid" value="695d36a1-a0b2-4c36-a00d-060ebd8b1645"/>
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

      it "updates mod-data.json" do
        expect(JSON.parse(File.read("mod-data.json"))).to include({
          "695d36a1-a0b2-4c36-a00d-060ebd8b1645" => hash_including({
            "is_installed" => true,
            "mod_name" => "Test Mod",
            "uuid" => "695d36a1-a0b2-4c36-a00d-060ebd8b1645",
            "number" => 1
          })
        })
      end
    end
  end
end
