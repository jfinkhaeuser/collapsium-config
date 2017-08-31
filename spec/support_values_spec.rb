require 'spec_helper'
require_relative '../lib/collapsium-config/support/values'

describe Collapsium::Config::Support::Values do
  let(:tester) { Class.new { extend Collapsium::Config::Support::Values } }

  context "#array_value" do
    it "splits a comma separated string" do
      expect(tester.array_value("foo,bar")).to eql %w[foo bar]
    end

    it "strips spaces from comma separated strings" do
      expect(tester.array_value(" foo ,  bar ")).to eql %w[foo bar]
    end

    it "turns single strings into an array" do
      expect(tester.array_value("foo")).to eql %w[foo]
    end

    it "strips spaces from single strings" do
      expect(tester.array_value(" foo ")).to eql %w[foo]
    end

    it "strips array elements" do
      expect(tester.array_value(['foo ', ' bar'])).to eql %w[foo bar]
    end

    it "wraps other values into arrays" do
      expect(tester.array_value({})).to eql [{}]
      expect(tester.array_value(42)).to eql [42]
    end

    it "handles mixed arrays well" do
      expect(tester.array_value([42, 'foo'])).to eql [42, 'foo']
    end
  end
end
