require "pp"
require "fakefs/spec_helpers"
require "json"

require_relative "../src/common"

RSpec.describe "common.rb" do
  include FakeFS::SpecHelpers

  describe "#safe_mkdir" do
    context "when no directory exists" do
      before do
        safe_mkdir("safe_mkdir")
      end

      it "makes a directory" do
        expect(Dir.exist?("safe_mkdir")).to be(true)
      end
    end
  end

  describe "#safe_cp" do
    context "when no file exists" do
      before do
        FileUtils.touch("safe_cp.txt")

        safe_cp("safe_cp.txt", "safe_cp_copy.txt")
      end

      it "creates a copy of the file" do
        expect(File.exist?("safe_cp_copy.txt")).to be(true)
      end
    end

    context "when the dest is a directory" do
      before do
        FileUtils.mkdir("destination")
        FileUtils.touch("dest_is_a_dir.txt")

        safe_cp("dest_is_a_dir.txt", "destination")
      end

      it "copies the file to the destination dir" do
        expect(File.exist?("dest_is_a_dir.txt")).to be(true)
        expect(File.exist?(File.join("destination", "dest_is_a_dir.txt"))).to be(true)
      end
    end
  end

  describe "#safe_create" do
    context "when no file exists" do
      before do
        safe_create("new_file.txt")
      end

      it "creates the file" do
        expect(File.exist?("new_file.txt")).to be(true)
      end
    end
  end

  describe "#get_json_data" do
    context "when the json file exists" do
      before do
        File.write("data.json", %q[{"foo": "bar"}])
      end

      it "loads the json file" do
        expect(get_json_data("data.json")).to eq({
          "foo" => "bar"
        })
      end
    end
  end

  describe "#save_json_data" do
    context "when json is valid" do
      before do
        save_json_data("data.json", { bar: "dat" })
      end

      it "saves the json" do
        expect(JSON.parse(File.read("data.json"))).to eq({
          "bar" => "dat"
        })
      end
    end
  end
end
