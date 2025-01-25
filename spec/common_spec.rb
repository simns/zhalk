require "fakefs/spec_helpers"

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
        FileUtils.touch("dest-is-a-dir.txt")

        safe_cp("dest-is-a-dir.txt", "destination")
      end

      it "copies the file to the destination dir" do
        expect(File.exist?(File.join("destination", "dest-is-a-dir.txt"))).to be(true)
      end
    end
  end
end
