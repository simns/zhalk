require "pp"
require "fakefs/spec_helpers"

require_relative "../src/base_cmd"

RSpec.describe BaseCmd do
  include FakeFS::SpecHelpers

  let(:base_cmd) { BaseCmd.new }
  let(:logger) { spy }

  before do
    allow(Volo).to receive(:new).and_return(logger)
  end

  describe "#safe_mkdir" do
    context "when no directory exists" do
      before do
        base_cmd.safe_mkdir("safe_mkdir")
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

        base_cmd.safe_cp("safe_cp.txt", "safe_cp_copy.txt")
      end

      it "creates a copy of the file" do
        expect(File.exist?("safe_cp_copy.txt")).to be(true)
      end
    end

    context "when the dest is a directory" do
      before do
        FileUtils.mkdir("destination")
        FileUtils.touch("dest_is_a_dir.txt")

        base_cmd.safe_cp("dest_is_a_dir.txt", "destination")
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
        base_cmd.safe_create("new_file.txt")
      end

      it "creates the file" do
        expect(File.exist?("new_file.txt")).to be(true)
      end
    end
  end
end
