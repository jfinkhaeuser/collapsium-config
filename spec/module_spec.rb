require 'spec_helper'
      require 'pry'
require_relative '../lib/collapsium-config'

include Collapsium::Config

describe Collapsium::Config do
  before do
    @data_path = File.join(File.dirname(__FILE__), 'data')
    ENV.delete("SOME_PATH")
    ENV.delete("SOME")
    ENV.delete("PATH")
  end

  it "fails to load configuration from the default path (it does not exist)" do
    expect(Collapsium::Config.config_file).to eql \
      Collapsium::Config::DEFAULT_CONFIG_PATH
    expect(config.empty?).to be_truthy
  end

  describe "providing a config file path" do
    before :each do
      Collapsium::Config.config_file = Collapsium::Config::DEFAULT_CONFIG_PATH
    end

    it "fails to load configuration files of unrecognized formats" do
      Collapsium::Config.config_file = File.join(@data_path, 'foo.bar')
      expect { config.empty? }.to raise_error(ArgumentError)
    end

    it "loads configuration from an existing path" do
      Collapsium::Config.config_file = File.join(@data_path, 'global.yml')
      expect { config.empty? }.not_to raise_error
      expect(config.empty?).to be_falsy
    end

    it "does not load the same configuration twice" do
      Collapsium::Config.config_file = File.join(@data_path, 'global.yml')
      cfg1 = config

      Collapsium::Config.config_file = File.join(@data_path, 'global.yml')
      cfg2 = config

      expect(cfg1.object_id).to eql cfg2.object_id
    end

    it "returns a config hash capable of environment overrides" do
      Collapsium::Config.config_file = File.join(@data_path, 'global.yml')

      # Pre environment manipulation
      expect(config["some.path"]).to eql 123

      # With environment manipulation
      ENV["SOME_PATH"] = "override"

      expect(config["some.path"]).to eql "override"
      expect(config["some"]["path"]).to eql "override"
    end
  end
end
