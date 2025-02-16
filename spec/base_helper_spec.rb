# frozen_string_literal: true

require "pp"
require "fakefs/spec_helpers"
require "json"

require_relative "../src/helpers/base_helper"

RSpec.describe BaseHelper do
  include FakeFS::SpecHelpers

  let(:base_helper) { BaseHelper.new }

  describe "#get_json_data" do
    context "when the json file exists" do
      before do
        File.write("data.json", '{"foo": "bar"}')
      end

      it "loads the json file" do
        expect(base_helper.get_json_data("data.json")).to eq({
          "foo" => "bar"
        })
      end
    end
  end

  describe "#save_json_data" do
    context "when json is valid" do
      before do
        base_helper.save_json_data("data.json", { bar: "dat" })
      end

      it "saves the json" do
        expect(JSON.parse(File.read("data.json"))).to eq({
          "bar" => "dat"
        })
      end
    end
  end
end
