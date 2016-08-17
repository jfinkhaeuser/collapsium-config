require 'spec_helper'
require_relative '../lib/collapsium-config/configuration'

describe Collapsium::Config::Configuration do
  before do
    @data_path = File.join(File.dirname(__FILE__), 'data')
  end

  describe "basic file loading" do
    it "fails to load a nonexistent file" do
      expect { Collapsium::Config::Configuration.load_config("_nope_.yaml") }.to \
        raise_error Errno::ENOENT
    end

    it "is asked to load an unrecognized extension" do
      expect { Collapsium::Config::Configuration.load_config("_nope_.cfg") }.to \
        raise_error ArgumentError
    end

    it "loads a yaml config with a top-level hash correctly" do
      config = File.join(@data_path, 'hash.yml')
      cfg = Collapsium::Config::Configuration.load_config(config)

      expect(cfg["foo"]).to eql "bar"
      expect(cfg["baz"]).to eql "quux"
    end

    it "loads a yaml config with a top-level array correctly" do
      config = File.join(@data_path, 'array.yaml')
      cfg = Collapsium::Config::Configuration.load_config(config)

      expect(cfg["config"]).to eql %w(foo bar)
    end

    it "loads a JSON config correctly" do
      config = File.join(@data_path, 'test.json')
      cfg = Collapsium::Config::Configuration.load_config(config)

      expect(cfg["foo"]).to eql "bar"
      expect(cfg["baz"]).to eql 42
    end

    it "treats an empty YAML file as an empty hash" do
      config = File.join(@data_path, 'empty.yml')
      cfg = Collapsium::Config::Configuration.load_config(config)
      expect(cfg).to be_empty
    end
  end

  describe "merge behaviour" do
    it "merges a hashed config correctly" do
      config = File.join(@data_path, 'merge-hash.yml')
      cfg = Collapsium::Config::Configuration.load_config(config)

      expect(cfg["asdf"]).to eql 1
      expect(cfg["foo.bar"]).to eql "baz"
      expect(cfg["foo.quux"]).to eql [1, 42]
      expect(cfg["foo.baz"]).to eql 3.14
      expect(cfg["blargh"]).to eql false
    end

    it "merges an array config correctly" do
      config = File.join(@data_path, 'merge-array.yaml')
      cfg = Collapsium::Config::Configuration.load_config(config)

      expect(cfg["config"]).to eql %w(foo bar baz)
    end

    it "merges an array and hash config" do
      config = File.join(@data_path, 'merge-fail.yaml')
      cfg = Collapsium::Config::Configuration.load_config(config)

      expect(cfg["config"]).to eql %w(array in main config)
      expect(cfg["local"]).to eql "override is a hash"
    end

    it "overrides configuration variables from the environment" do
      config = File.join(@data_path, 'hash.yml')
      cfg = Collapsium::Config::Configuration.load_config(config)

      ENV["BAZ"] = "override"
      expect(cfg["foo"]).to eql "bar"
      expect(cfg["baz"]).to eql "override"
      ENV.delete("BAZ")
    end

    it "parses JSON when overriding from the environment" do
      config = File.join(@data_path, 'hash.yml')
      cfg = Collapsium::Config::Configuration.load_config(config)

      ENV["BAZ"] = '{ "json_key": "json_value" }'
      expect(cfg["foo"]).to eql "bar"
      expect(cfg["baz"].is_a?(Hash)).to be_truthy
      expect(cfg["baz.json_key"]).to eql "json_value"
      ENV.delete("BAZ")
    end
  end

  describe "extend functionality" do
    it "extends configuration hashes" do
      config = File.join(@data_path, 'driverconfig.yml')
      cfg = Collapsium::Config::Configuration.load_config(config)

      # First, test for non-extended values
      expect(cfg["drivers.mock.mockoption"]).to eql 42
      expect(cfg["drivers.branch1.branch1option"]).to eql "foo"
      expect(cfg["drivers.branch2.branch2option"]).to eql "bar"
      expect(cfg["drivers.leaf.leafoption"]).to eql "baz"

      # Now test extended values
      expect(cfg["drivers.branch1.mockoption"]).to eql 42
      expect(cfg["drivers.branch2.mockoption"]).to eql 42
      expect(cfg["drivers.leaf.mockoption"]).to eql 42

      expect(cfg["drivers.branch2.branch1option"]).to eql "foo"
      expect(cfg["drivers.leaf.branch1option"]).to eql "override" # not "foo" !

      expect(cfg["drivers.leaf.branch2option"]).to eql "bar"

      # Also test that all levels go back to base == mock
      expect(cfg["drivers.branch1.base"]).to eql 'mock'
      expect(cfg["drivers.branch2.base"]).to eql 'mock'
      expect(cfg["drivers.leaf.base"]).to eql 'mock'
    end

    it "extends configuration hashes when the base does not exist" do
      config = File.join(@data_path, 'driverconfig.yml')
      cfg = Collapsium::Config::Configuration.load_config(config)

      # Ensure the hash contains its own value
      expect(cfg["drivers.base_does_not_exist.some"]).to eql "value"

      # Also ensure the "base" is set properly
      expect(cfg["drivers.base_does_not_exist.base"]).to eql "nonexistent_base"
    end

    it "does nothing when a hash extends itself" do
      config = File.join(@data_path, 'recurse.yml')
      cfg = Collapsium::Config::Configuration.load_config(config)

      # Most of the test is already over, i.e. we haven't run into recursion
      # issues.
      expect(cfg["extends_itself.test"]).to eql 42
    end
  end

  describe "include functionality" do
    it "can include a file" do
      config = File.join(@data_path, 'include-simple.yml')
      cfg = Collapsium::Config::Configuration.load_config(config)

      expect(cfg["foo"]).to eql 42
      expect(cfg["bar"]).to eql 'quux'
    end

    it "can include multiple files in different languages" do
      config = File.join(@data_path, 'include-multiple.yml')
      cfg = Collapsium::Config::Configuration.load_config(config)

      expect(cfg["foo"]).to eql 42
      expect(cfg["bar"]).to eql 'quux'
      expect(cfg["baz"]).to eql 'test'
    end

    it "can resolve includes recursively" do
      config = File.join(@data_path, 'include-recursive.yml')
      cfg = Collapsium::Config::Configuration.load_config(config)

      expect(cfg["foo"]).to eql 42
      expect(cfg["bar"]).to eql 'quux'
      expect(cfg["baz"]).to eql 'test'
    end

    it "extends configuration from across includes" do
      config = File.join(@data_path, 'include-extend.yml')
      cfg = Collapsium::Config::Configuration.load_config(config)

      expect(cfg["foo.bar"]).to eql 'quux'
      expect(cfg["foo.baz"]).to eql 'test'
      expect(cfg["bar.foo"]).to eql 'something'
      expect(cfg["bar.baz"]).to eql 42
    end
  end

  describe "behaves like a UberHash" do
    it "passed through access methods" do
      config = File.join(@data_path, 'hash.yml')
      cfg = Collapsium::Config::Configuration.load_config(config)

      # UberHash's [] requires one argument
      expect { cfg[] }.to raise_error(ArgumentError)
    end
  end

  describe "ERB templating" do
    it "replaces variables" do
      config = File.join(@data_path, 'template.yml')

      data = {
        my_var: Random.rand
      }
      cfg = Collapsium::Config::Configuration.load_config(config, data: data)

      expect(cfg["foo"]).to eql "bar"
      expect(cfg["baz"]).to eql data[:my_var]
    end
  end
end
