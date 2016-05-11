require 'spec_helper'
require_relative '../lib/collapsium-config'

include Collapsium::Config

describe Collapsium::Config do
  before do
    @data_path = File.join(File.dirname(__FILE__), 'data')
  end

  it "fails to load configuration from the default path (it does not exist)" do
    expect(config.empty?).to be_truthy
  end

  it "fails to load configuration files of unrecognized formats" do
    Collapsium::Config.config_file = File.join(@data_path, 'foo.bar')
    expect { config.empty? }.to raise_error(ArgumentError)
  end

  it "loads configuration from an existing path" do
    Collapsium::Config.config_file = File.join(@data_path, 'global.yml')
    expect { config.empty? }.not_to raise_error(ArgumentError)
    expect(config.empty?).to be_falsy
  end
end
