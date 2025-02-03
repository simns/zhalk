require "pp"
require "fakefs/spec_helpers"
require "json"
require "date"

require_relative "../src/reorder_cmd"
require_relative "../src/helpers/modsettings_helper"
require_relative "../src/helpers/mod_data_helper"
require_relative "../src/helpers/config_helper"

RSpec.describe ReorderCmd do
  include FakeFS::SpecHelpers

  describe "#reorder_cmd" do
    let(:reorder_cmd) { ReorderCmd.new }
    let(:modsettings_helper) { ModsettingsHelper.new(config_helper) }
    let(:config_helper) { ConfigHelper.new }
    let(:mod_data_helper) { ModDataHelper.new }

    before do
      FileUtils.touch("conf.toml")

      allow(ModsettingsHelper).to receive(:new).and_return(modsettings_helper)
      allow(modsettings_helper).to receive(:modsettings_dir).and_return(".")
      allow(modsettings_helper).to receive(:puts)
      allow(ModDataHelper).to receive(:new).and_return(mod_data_helper)
      allow(mod_data_helper).to receive(:puts)
      allow(reorder_cmd).to receive(:puts)
    end

    context "when mod-data.json is empty" do
      before do
        File.write("mod-data.json", "{}")
      end

      context "when modsettings.lsx has existing mods" do
        before do
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
              <attribute id="Folder" type="LSString" value="Example mod"/>
              <attribute id="MD5" type="LSString" value=""/>
              <attribute id="Name" type="LSString" value="Example mod"/>
              <attribute id="UUID" type="guid" value="ab941c3d-0827-4833-bbb4-dbb07ac29983"/>
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

          allow(STDIN).to receive(:gets).and_return("1")

          reorder_cmd.run
        end

        it "stops because no mods were found" do
          expect(File.read("mod-data.json")).to eq("{}")
          expect(File.read("modsettings.lsx")).to eq(
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
              <attribute id="Folder" type="LSString" value="Example mod"/>
              <attribute id="MD5" type="LSString" value=""/>
              <attribute id="Name" type="LSString" value="Example mod"/>
              <attribute id="UUID" type="guid" value="ab941c3d-0827-4833-bbb4-dbb07ac29983"/>
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
        end
      end
    end

    context "when mod-data.json has existing mods" do
      before do
        File.write("mod-data.json", {
          "c366d5f3-2afc-41d0-b4ac-de15257384e0" => {
            "is_installed" => true,
            "mod_name" => "Existing mod",
            "uuid" => "c366d5f3-2afc-41d0-b4ac-de15257384e0",
            "number" => 1,
            "created_at" => Time.now.to_s,
            "updated_at" => Time.now.to_s
          },
          "a8a472fb-e423-4315-b4e3-eeb0cf3af88d" => {
            "is_installed" => true,
            "mod_name" => "Existing mod 2",
            "uuid" => "a8a472fb-e423-4315-b4e3-eeb0cf3af88d",
            "number" => 2,
            "created_at" => Time.now.to_s,
            "updated_at" => Time.now.to_s
          }
        }.to_json)
      end

      context "when modsettings.lsx has no existing mods" do
        before do
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
MODSETTINGS
          )

          allow(STDIN).to receive(:gets).and_return("1", "e")

          reorder_cmd.run
        end

        it "modifies mod-data.json to reflect new order" do
          expect(JSON.parse(File.read("mod-data.json"))).to include({
            "c366d5f3-2afc-41d0-b4ac-de15257384e0" => hash_including({
              "is_installed" => true,
              "mod_name" => "Existing mod",
              "uuid" => "c366d5f3-2afc-41d0-b4ac-de15257384e0",
              "number" => 2
            }),
            "a8a472fb-e423-4315-b4e3-eeb0cf3af88d" => hash_including({
              "is_installed" => true,
              "mod_name" => "Existing mod 2",
              "uuid" => "a8a472fb-e423-4315-b4e3-eeb0cf3af88d",
              "number" => 1
            })
          })
        end

        it "does not modify modsettings.lsx" do
          expect(File.read("modsettings.lsx")).to eq(
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
MODSETTINGS
                                                  )
        end
      end

      context "when modsettings.lsx has the same existing mods" do
        context "when the user selects to move a mod after another mod" do
          before do
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
              <attribute id="Folder" type="LSString" value="GustavDev"/>
              <attribute id="MD5" type="LSString" value=""/>
              <attribute id="Name" type="LSString" value="GustavDev"/>
              <attribute id="PublishHandle" type="uint64" value="0"/>
              <attribute id="UUID" type="guid" value="28ac9ce2-2aba-8cda-b3b5-6e922f71b6b8"/>
              <attribute id="Version64" type="int64" value="36028797018963968"/>
            </node>
            <node id="ModuleShortDesc">
              <attribute id="Folder" type="LSString" value="Existing mod"/>
              <attribute id="MD5" type="LSString" value=""/>
              <attribute id="Name" type="LSString" value="Existing mod"/>
              <attribute id="PublishHandle" type="uint64" value="0"/>
              <attribute id="UUID" type="guid" value="c366d5f3-2afc-41d0-b4ac-de15257384e0"/>
              <attribute id="Version64" type="int64" value=""/>
            </node>
            <node id="ModuleShortDesc">
              <attribute id="Folder" type="LSString" value="Existing mod 2"/>
              <attribute id="MD5" type="LSString" value=""/>
              <attribute id="Name" type="LSString" value="Existing mod 2"/>
              <attribute id="PublishHandle" type="uint64" value="0"/>
              <attribute id="UUID" type="guid" value="a8a472fb-e423-4315-b4e3-eeb0cf3af88d"/>
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

            allow(STDIN).to receive(:gets).and_return("1", "e")

            reorder_cmd.run
          end

          it "modifies mod-data.json to reflect new order" do
            expect(JSON.parse(File.read("mod-data.json"))).to include({
              "c366d5f3-2afc-41d0-b4ac-de15257384e0" => hash_including({
                "is_installed" => true,
                "mod_name" => "Existing mod",
                "uuid" => "c366d5f3-2afc-41d0-b4ac-de15257384e0",
                "number" => 2
              }),
              "a8a472fb-e423-4315-b4e3-eeb0cf3af88d" => hash_including({
                "is_installed" => true,
                "mod_name" => "Existing mod 2",
                "uuid" => "a8a472fb-e423-4315-b4e3-eeb0cf3af88d",
                "number" => 1
              })
            })
          end

          it "modifies modsettings.lsx to reflect new order" do
            expect(File.read("modsettings.lsx")).to eq(
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
              <attribute id="Folder" type="LSString" value="GustavDev"/>
              <attribute id="MD5" type="LSString" value=""/>
              <attribute id="Name" type="LSString" value="GustavDev"/>
              <attribute id="PublishHandle" type="uint64" value="0"/>
              <attribute id="UUID" type="guid" value="28ac9ce2-2aba-8cda-b3b5-6e922f71b6b8"/>
              <attribute id="Version64" type="int64" value="36028797018963968"/>
            </node>
            <node id="ModuleShortDesc">
              <attribute id="Folder" type="LSString" value="Existing mod 2"/>
              <attribute id="MD5" type="LSString" value=""/>
              <attribute id="Name" type="LSString" value="Existing mod 2"/>
              <attribute id="PublishHandle" type="uint64" value="0"/>
              <attribute id="UUID" type="guid" value="a8a472fb-e423-4315-b4e3-eeb0cf3af88d"/>
              <attribute id="Version64" type="int64" value=""/>
            </node>
            <node id="ModuleShortDesc">
              <attribute id="Folder" type="LSString" value="Existing mod"/>
              <attribute id="MD5" type="LSString" value=""/>
              <attribute id="Name" type="LSString" value="Existing mod"/>
              <attribute id="PublishHandle" type="uint64" value="0"/>
              <attribute id="UUID" type="guid" value="c366d5f3-2afc-41d0-b4ac-de15257384e0"/>
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
          end
        end

        context "when the user incorrectly selects a mod to move after" do
          before do
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
              <attribute id="Folder" type="LSString" value="GustavDev"/>
              <attribute id="MD5" type="LSString" value=""/>
              <attribute id="Name" type="LSString" value="GustavDev"/>
              <attribute id="PublishHandle" type="uint64" value="0"/>
              <attribute id="UUID" type="guid" value="28ac9ce2-2aba-8cda-b3b5-6e922f71b6b8"/>
              <attribute id="Version64" type="int64" value="36028797018963968"/>
            </node>
            <node id="ModuleShortDesc">
              <attribute id="Folder" type="LSString" value="Existing mod"/>
              <attribute id="MD5" type="LSString" value=""/>
              <attribute id="Name" type="LSString" value="Existing mod"/>
              <attribute id="PublishHandle" type="uint64" value="0"/>
              <attribute id="UUID" type="guid" value="c366d5f3-2afc-41d0-b4ac-de15257384e0"/>
              <attribute id="Version64" type="int64" value=""/>
            </node>
            <node id="ModuleShortDesc">
              <attribute id="Folder" type="LSString" value="Existing mod 2"/>
              <attribute id="MD5" type="LSString" value=""/>
              <attribute id="Name" type="LSString" value="Existing mod 2"/>
              <attribute id="PublishHandle" type="uint64" value="0"/>
              <attribute id="UUID" type="guid" value="a8a472fb-e423-4315-b4e3-eeb0cf3af88d"/>
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

            allow(STDIN).to receive(:gets).and_return("1,2", "a 2")
          end

          it "stops before writing any data to the files" do
            expect(reorder_cmd).to receive(:process_command)
            expect(reorder_cmd).to_not receive(:put_after_mod)
            expect(reorder_cmd).to_not receive(:write_new_mod_data)
            expect(reorder_cmd).to_not receive(:write_new_modsettings)

            reorder_cmd.run
          end
        end
      end

      context "when modsettings.lsx has extra mods" do
        before do
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
              <attribute id="Folder" type="LSString" value="GustavDev"/>
              <attribute id="MD5" type="LSString" value=""/>
              <attribute id="Name" type="LSString" value="GustavDev"/>
              <attribute id="PublishHandle" type="uint64" value="0"/>
              <attribute id="UUID" type="guid" value="28ac9ce2-2aba-8cda-b3b5-6e922f71b6b8"/>
              <attribute id="Version64" type="int64" value="36028797018963968"/>
            </node>
            <node id="ModuleShortDesc">
              <attribute id="Folder" type="LSString" value="An Extra mod"/>
              <attribute id="MD5" type="LSString" value=""/>
              <attribute id="Name" type="LSString" value="An Extra mod"/>
              <attribute id="PublishHandle" type="uint64" value="0"/>
              <attribute id="UUID" type="guid" value="6700761a-1da5-4902-a3b1-24ddd37254c7"/>
              <attribute id="Version64" type="int64" value=""/>
            </node>
            <node id="ModuleShortDesc">
              <attribute id="Folder" type="LSString" value="Existing mod"/>
              <attribute id="MD5" type="LSString" value=""/>
              <attribute id="Name" type="LSString" value="Existing mod"/>
              <attribute id="PublishHandle" type="uint64" value="0"/>
              <attribute id="UUID" type="guid" value="c366d5f3-2afc-41d0-b4ac-de15257384e0"/>
              <attribute id="Version64" type="int64" value=""/>
            </node>
            <node id="ModuleShortDesc">
              <attribute id="Folder" type="LSString" value="An Extra mod 2"/>
              <attribute id="MD5" type="LSString" value=""/>
              <attribute id="Name" type="LSString" value="An Extra mod 2"/>
              <attribute id="PublishHandle" type="uint64" value="0"/>
              <attribute id="UUID" type="guid" value="6c41a621-0855-458f-85bf-1b2d006e9ba1"/>
              <attribute id="Version64" type="int64" value=""/>
            </node>
            <node id="ModuleShortDesc">
              <attribute id="Folder" type="LSString" value="Existing mod 2"/>
              <attribute id="MD5" type="LSString" value=""/>
              <attribute id="Name" type="LSString" value="Existing mod 2"/>
              <attribute id="PublishHandle" type="uint64" value="0"/>
              <attribute id="UUID" type="guid" value="a8a472fb-e423-4315-b4e3-eeb0cf3af88d"/>
              <attribute id="Version64" type="int64" value=""/>
            </node>
            <node id="ModuleShortDesc">
              <attribute id="Folder" type="LSString" value="An Extra mod 3"/>
              <attribute id="MD5" type="LSString" value=""/>
              <attribute id="Name" type="LSString" value="An Extra mod 3"/>
              <attribute id="PublishHandle" type="uint64" value="0"/>
              <attribute id="UUID" type="guid" value="cb6655bf-a304-4305-84dc-706c9e624040"/>
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

          allow(STDIN).to receive(:gets).and_return("1", "e")

          reorder_cmd.run
        end

        it "reorders mod-data.json as usual" do
          expect(JSON.parse(File.read("mod-data.json"))).to include({
            "c366d5f3-2afc-41d0-b4ac-de15257384e0" => hash_including({
              "is_installed" => true,
              "mod_name" => "Existing mod",
              "uuid" => "c366d5f3-2afc-41d0-b4ac-de15257384e0",
              "number" => 2
            }),
            "a8a472fb-e423-4315-b4e3-eeb0cf3af88d" => hash_including({
              "is_installed" => true,
              "mod_name" => "Existing mod 2",
              "uuid" => "a8a472fb-e423-4315-b4e3-eeb0cf3af88d",
              "number" => 1
            })
          })
        end

        it "keeps extra mods at the beginning and found mods at the end in the order specified" do
          expect(File.read("modsettings.lsx")).to eq(
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
              <attribute id="Folder" type="LSString" value="GustavDev"/>
              <attribute id="MD5" type="LSString" value=""/>
              <attribute id="Name" type="LSString" value="GustavDev"/>
              <attribute id="PublishHandle" type="uint64" value="0"/>
              <attribute id="UUID" type="guid" value="28ac9ce2-2aba-8cda-b3b5-6e922f71b6b8"/>
              <attribute id="Version64" type="int64" value="36028797018963968"/>
            </node>
            <node id="ModuleShortDesc">
              <attribute id="Folder" type="LSString" value="An Extra mod"/>
              <attribute id="MD5" type="LSString" value=""/>
              <attribute id="Name" type="LSString" value="An Extra mod"/>
              <attribute id="PublishHandle" type="uint64" value="0"/>
              <attribute id="UUID" type="guid" value="6700761a-1da5-4902-a3b1-24ddd37254c7"/>
              <attribute id="Version64" type="int64" value=""/>
            </node>
            <node id="ModuleShortDesc">
              <attribute id="Folder" type="LSString" value="An Extra mod 2"/>
              <attribute id="MD5" type="LSString" value=""/>
              <attribute id="Name" type="LSString" value="An Extra mod 2"/>
              <attribute id="PublishHandle" type="uint64" value="0"/>
              <attribute id="UUID" type="guid" value="6c41a621-0855-458f-85bf-1b2d006e9ba1"/>
              <attribute id="Version64" type="int64" value=""/>
            </node>
            <node id="ModuleShortDesc">
              <attribute id="Folder" type="LSString" value="An Extra mod 3"/>
              <attribute id="MD5" type="LSString" value=""/>
              <attribute id="Name" type="LSString" value="An Extra mod 3"/>
              <attribute id="PublishHandle" type="uint64" value="0"/>
              <attribute id="UUID" type="guid" value="cb6655bf-a304-4305-84dc-706c9e624040"/>
              <attribute id="Version64" type="int64" value=""/>
            </node>
            <node id="ModuleShortDesc">
              <attribute id="Folder" type="LSString" value="Existing mod 2"/>
              <attribute id="MD5" type="LSString" value=""/>
              <attribute id="Name" type="LSString" value="Existing mod 2"/>
              <attribute id="PublishHandle" type="uint64" value="0"/>
              <attribute id="UUID" type="guid" value="a8a472fb-e423-4315-b4e3-eeb0cf3af88d"/>
              <attribute id="Version64" type="int64" value=""/>
            </node>
            <node id="ModuleShortDesc">
              <attribute id="Folder" type="LSString" value="Existing mod"/>
              <attribute id="MD5" type="LSString" value=""/>
              <attribute id="Name" type="LSString" value="Existing mod"/>
              <attribute id="PublishHandle" type="uint64" value="0"/>
              <attribute id="UUID" type="guid" value="c366d5f3-2afc-41d0-b4ac-de15257384e0"/>
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
        end
      end
    end
  end
end
