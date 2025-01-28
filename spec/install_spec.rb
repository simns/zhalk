require "pp"
require "fakefs/spec_helpers"
require "nokogiri"

require_relative "../src/install"

RSpec.describe "install.rb" do
  include FakeFS::SpecHelpers

  describe "#insert_into_modsettings" do
    context "when there aren't existing mods" do
      before do
        File.write("modsettings.lsx",
                   <<-EXAMPLE
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
EXAMPLE
        )

        allow(self).to receive(:puts)
        allow(self).to receive(:get_toml_config).and_return({})
        allow(self).to receive(:modsettings_dir).and_return(".")

        insert_into_modsettings({
          "Mods" => [
            {
              "Author" => "Poopie",
              "Name" => "Test Mod",
              "Folder" => "Test Folder",
              "Version" => "",
              "Description" => "Example description",
              "UUID" => "658ba936-8a5c-40f1-94a6-7bf8d874b66e",
              "Created" => "2024-01-01T03:00:00.1238948+09:00",
              "Dependencies" => [],
              "Group" => "82e1e744-3ea9-4cdd-9d4a-1bb46a8bb2c7",
            },
          ],
          "MD5" => "54c3136171518f973ad518b43f3f35ae",
        })
      end

      it "adds the mod to modsettings.lsx" do
        expect(File.read("modsettings.lsx")).to eq(
                                                  <<-NEWFILE
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
NEWFILE
                                                )
      end
    end

    context "when the target mod is already present" do
      before do
        File.write("modsettings.lsx",
                   <<-EXAMPLE
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
EXAMPLE
        )

        allow(self).to receive(:get_toml_config).and_return({})
        allow(self).to receive(:modsettings_dir).and_return(".")
      end

      it "warns that the entry already exists" do
        expect {
          insert_into_modsettings({
            "Mods" => [
              {
                "Author" => "Poopie",
                "Name" => "Test Mod",
                "Folder" => "Test Folder",
                "Version" => "",
                "Description" => "Example description",
                "UUID" => "cf5175fb-0a7c-4af3-b51c-14b683a5cb7d",
                "Created" => "2024-01-01T03:00:00.1238948+09:00",
                "Dependencies" => [],
                "Group" => "82e1e744-3ea9-4cdd-9d4a-1bb46a8bb2c7",
              },
            ],
            "MD5" => "54c3136171518f973ad518b43f3f35ae",
          })
        }.to output("WARN: Mod entry already exists in modsettings.lsx.\n").to_stdout
      end

      it "doesn't modify anything" do
        insert_into_modsettings({
          "Mods" => [
            {
              "Author" => "Poopie",
              "Name" => "Test Mod",
              "Folder" => "Test Folder",
              "Version" => "",
              "Description" => "Example description",
              "UUID" => "cf5175fb-0a7c-4af3-b51c-14b683a5cb7d",
              "Created" => "2024-01-01T03:00:00.1238948+09:00",
              "Dependencies" => [],
              "Group" => "82e1e744-3ea9-4cdd-9d4a-1bb46a8bb2c7",
            },
          ],
          "MD5" => "54c3136171518f973ad518b43f3f35ae",
        })

        expect(File.read("modsettings.lsx")).to eq(
                                                  <<-EXAMPLE
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
EXAMPLE
                                                )
      end
    end
  end

  describe "#update_mod_data" do
    context "when mod-data.json is empty" do
      before do
        update_mod_data({}, {
          "Mods" => [
            {
              "Author" => "Poopie",
              "Name" => "Test Mod",
              "Folder" => "Test Folder",
              "Version" => "",
              "Description" => "Example description",
              "UUID" => "6df04e78-79ba-4c56-aa68-67e843f78ac9",
              "Created" => "2024-01-01T03:00:00.1238948+09:00",
              "Dependencies" => [],
              "Group" => "82e1e744-3ea9-4cdd-9d4a-1bb46a8bb2c7",
            },
          ],
          "MD5" => "54c3136171518f973ad518b43f3f35ae",
        })
      end

      it "saves to mod-data.json" do
        expect(JSON.parse(File.read("mod-data.json"))).to include({
          "6df04e78-79ba-4c56-aa68-67e843f78ac9" => hash_including({
            "is_installed" => true,
            "mod_name" => "Test Mod",
            "uuid" => "6df04e78-79ba-4c56-aa68-67e843f78ac9",
            "number" => 1,
          }),
        })
      end
    end

    context "when mod-data.json has the target entry as uninstalled" do
      before do
        update_mod_data({
          "18f35d9d-aaaa-4df6-8d3e-c2cdc5ae0c1b" => {
            "is_installed" => false,
            "mod_name" => "Test Mod",
            "uuid" => "18f35d9d-aaaa-4df6-8d3e-c2cdc5ae0c1b",
            "number" => 1,
            "created_at" => "2025-01-28 18:15:04 +0900",
            "updated_at" => "2025-01-28 18:15:04 +0900",
          },
        }, {
          "Mods" => [
            {
              "Author" => "Poopie",
              "Name" => "Test Mod",
              "Folder" => "Test Folder",
              "Version" => "",
              "Description" => "Example description",
              "UUID" => "18f35d9d-aaaa-4df6-8d3e-c2cdc5ae0c1b",
              "Created" => "2024-01-01T03:00:00.1238948+09:00",
              "Dependencies" => [],
              "Group" => "82e1e744-3ea9-4cdd-9d4a-1bb46a8bb2c7",
            },
          ],
          "MD5" => "54c3136171518f973ad518b43f3f35ae",
        })
      end

      it "updates the entry to be installed" do
        expect(JSON.parse(File.read("mod-data.json"))).to include({
          "18f35d9d-aaaa-4df6-8d3e-c2cdc5ae0c1b" => hash_including({
            "is_installed" => true,
            "mod_name" => "Test Mod",
            "uuid" => "18f35d9d-aaaa-4df6-8d3e-c2cdc5ae0c1b",
            "number" => 1,
          }),
        })
      end
    end
  end
end
