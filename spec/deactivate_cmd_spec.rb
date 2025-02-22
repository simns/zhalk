# frozen_string_literal: true

require "pp"
require "fakefs/spec_helpers"
require "json"
require "date"

require_relative "../src/deactivate_cmd"
require_relative "../src/helpers/modsettings_helper"
require_relative "../src/helpers/config_helper"
require_relative "../src/helpers/constants"
require_relative "../src/utils/volo"

RSpec.describe DeactivateCmd do
  include FakeFS::SpecHelpers

  let(:logger) { spy }

  before do
    stub_const("ROOT_DIR", ".")

    allow(Volo).to receive(:new).and_return(logger)
  end

  describe "#run" do
    let(:deactivate_cmd) { DeactivateCmd.new }
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
          "e7714436-06aa-483f-bafc-8f1690422968" => {
            "is_installed" => true,
            "mod_name" => "Test Mod",
            "uuid" => "e7714436-06aa-483f-bafc-8f1690422968",
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
                          <attribute id="UUID" type="guid" value="e7714436-06aa-483f-bafc-8f1690422968"/>
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

        deactivate_cmd.run("1")
      end

      it "removes the mod from modsettings" do
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

      it "adds the mod entry to a file in 'inactive' folder" do
        expect(File.read(File.join(Constants::INACTIVE_DIR,
          "e7714436-06aa-483f-bafc-8f1690422968.xml"))).to eq(
            <<~XML.strip
              <node id="ModuleShortDesc">
                <attribute id="Folder" type="LSString" value="Test Folder"/>
                <attribute id="MD5" type="LSString" value="54c3136171518f973ad518b43f3f35ae"/>
                <attribute id="Name" type="LSString" value="Test Mod"/>
                <attribute id="UUID" type="guid" value="e7714436-06aa-483f-bafc-8f1690422968"/>
                <attribute id="Version64" type="int64" value=""/>
              </node>
            XML
          )
      end

      it "sets the mod as not installed in mod-data.json" do
        expect(JSON.parse(File.read("mod-data.json"))).to include({
          "e7714436-06aa-483f-bafc-8f1690422968" => hash_including({
            "is_installed" => false,
            "mod_name" => "Test Mod",
            "uuid" => "e7714436-06aa-483f-bafc-8f1690422968",
            "number" => 1
          })
        })
      end
    end

    context "when the target mod entry cannot be found in modsettings" do
      before do
        File.write("mod-data.json", {
          "bd75eb6e-6998-48ef-836a-72c38ad08e9b" => {
            "is_installed" => true,
            "mod_name" => "Test Mod",
            "uuid" => "bd75eb6e-6998-48ef-836a-72c38ad08e9b",
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

      it "raises an error before any backup is performed" do
        expect(logger).to receive(:error).with(
          "Could not find mod entry in modsettings.lsx. Cannot proceed."
        )

        deactivate_cmd.run("1")

        expect(JSON.parse(File.read("mod-data.json"))).to include({
          "bd75eb6e-6998-48ef-836a-72c38ad08e9b" => hash_including({
            "is_installed" => true,
            "mod_name" => "Test Mod",
            "uuid" => "bd75eb6e-6998-48ef-836a-72c38ad08e9b",
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

        expect(File.exist?(File.join(Constants::INACTIVE_DIR,
          "bd75eb6e-6998-48ef-836a-72c38ad08e9b.xml"))).to be(false)
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

        deactivate_cmd.run("1")
      end

      it "does not modify anything" do
        deactivate_cmd.run("1")

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

    context "when the target mod is already deactivated" do
      before do
        File.write("mod-data.json", {
          "2d191704-9e70-4a40-96b9-52019e8c93fd" => {
            "is_installed" => false,
            "mod_name" => "Test Mod",
            "uuid" => "2d191704-9e70-4a40-96b9-52019e8c93fd",
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

      it "prints that the target mod is already deactivated" do
        expect(logger).to receive(:info).with("Target mod is already deactivated.")

        deactivate_cmd.run("1")
      end

      it "does not modify anything" do
        deactivate_cmd.run("1")

        expect(JSON.parse(File.read("mod-data.json"))).to include({
          "2d191704-9e70-4a40-96b9-52019e8c93fd" => hash_including({
            "is_installed" => false,
            "mod_name" => "Test Mod",
            "uuid" => "2d191704-9e70-4a40-96b9-52019e8c93fd",
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
  end
end
