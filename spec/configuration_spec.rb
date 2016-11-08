require 'spec_helper'
require_relative '../lib/collapsium-config/configuration'

describe Collapsium::Config::Configuration do
  before(:all) do
    @data_path = File.join(File.dirname(__FILE__), 'data')
  end

  before(:each) do
    ENV.delete("BAZ")
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
    end

    it "parses JSON when overriding from the environment" do
      config = File.join(@data_path, 'hash.yml')
      cfg = Collapsium::Config::Configuration.load_config(config)

      ENV["BAZ"] = '{ "json_key": "json_value" }'
      expect(cfg["foo"]).to eql "bar"
      expect(cfg["baz"].is_a?(Hash)).to be_truthy
      expect(cfg["baz.json_key"]).to eql "json_value"
    end
  end

  describe "extend functionality" do
    context "merging" do
      before(:all) do
        @config_path = File.join(@data_path, 'driverconfig.yml')
        @config = Collapsium::Config::Configuration.load_config(@config_path)
      end

      context "drivers" do
        it "accepts mock drivers" do
          # There is no built-in driver labelled 'mock'
          expect(@config["drivers.mock.mockoption"]).to eql 42
        end

        it "merges a single ancestor" do
          # Check merged values
          expect(@config["drivers.branch1.branch1option"]).to eql "foo"
          expect(@config["drivers.branch1.mockoption"]).to eql 42

          # Check merge metadata
          expect(@config["drivers.branch1.extends"]).to be_nil
          expect(@config["drivers.branch1.base"]).to eql %w(.drivers.mock)
        end

        it "merges multiple ancestor depths" do
          # Check merged values
          expect(@config["drivers.branch2.branch2option"]).to eql "bar"
          expect(@config["drivers.branch2.branch1option"]).to eql "foo"
          expect(@config["drivers.branch2.mockoption"]).to eql 42

          # Check merge metadata
          expect(@config["drivers.branch2.extends"]).to be_nil
          expect(@config["drivers.branch2.base"]).to eql %w(.drivers.mock
                                                            .drivers.branch1)
        end

        it "merges from absolute paths" do
          # Check merged values
          expect(@config["drivers.branch3.branch3option"]).to eql "baz"
          expect(@config["drivers.branch3.global_opt"]).to eql "set"

          # Check merge metadata
          expect(@config["drivers.branch3.extends"]).to be_nil
          expect(@config["drivers.branch3.base"]).to eql %w(.global)
        end

        it "merges from sibling and absolute path" do
          # Check merged values
          expect(@config["drivers.leaf.leafoption"]).to eql "baz"
          expect(@config["drivers.leaf.branch2option"]).to eql "bar"
          expect(@config["drivers.leaf.branch1option"]).to eql "override"
          expect(@config["drivers.leaf.mockoption"]).to eql 42
          expect(@config["drivers.leaf.global_opt"]).to eql "set"

          # Check merge metadata
          expect(@config["drivers.leaf.extends"]).to be_nil
          expect(@config["drivers.leaf.base"]).to eql %w(.drivers.mock
                                                         .drivers.branch1
                                                         .drivers.branch2
                                                         .global)
        end

        it "merges from global and absolute path" do
          # Check merged values
          expect(@config["drivers.leaf2.leafoption"]).to eql "baz"
          expect(@config["drivers.leaf2.global_opt"]).to eql "set"
          expect(@config["drivers.leaf2.branch2option"]).to eql "bar"
          expect(@config["drivers.leaf2.branch1option"]).to eql "override"
          expect(@config["drivers.leaf2.mockoption"]).to eql 42

          # Check merge metadata
          expect(@config["drivers.leaf2.extends"]).to be_nil
          expect(@config["drivers.leaf2.base"]).to eql %w(.global
                                                          .drivers.mock
                                                          .drivers.branch1
                                                          .drivers.branch2)
        end

        it "works when a base does not exist" do
          # Ensure the hash contains its own value
          expect(@config["drivers.base_does_not_exist.some"]).to eql "value"

          # Also ensure the "base" is _not_ set properly
          expect(@config["drivers.base_does_not_exist.base"]).to be_nil

          # On the other hand, "extends" should stay.
          expect(@config["drivers.base_does_not_exist.extends"]).to eql \
            "nonexistent_base"
        end
      end

      context "non-driver values" do
        it "merges from absolute paths" do
          expect(@config["derived.test.foo"]).to eql 'bar'
          expect(@config["derived.test.some"]).to eql 'option'
        end

        it "can merge into list items" do
          expect(@config["derived.test2.0.foo"]).to eql 'bar'
          expect(@config["derived.test2.0.some"]).to eql 'option'
        end

        it "can merge from list items" do
          expect(@config["derived.test3.foo"]).to eql 'bar'
          expect(@config["derived.test3.some2"]).to eql 'option2'
        end

        it "accepts multiple extensions" do
          expect(@config["derived.test4.foo"]).to eql 'bar'
          expect(@config["derived.test4.some"]).to eql 'option_override'
          expect(@config["derived.test4.some2"]).to eql 'option2'
        end
      end
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

    it "can include multiple files from a comma-separated list" do
      config = File.join(@data_path, 'include-multiple2.yml')
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

    it "can include array configuration files" do
      config = File.join(@data_path, 'include-array.yml')
      cfg = Collapsium::Config::Configuration.load_config(config)

      expect(cfg["quux"]).to eql "baz"
      expect(cfg["config"]).to eql %w(foo bar)
    end

    it "works in nested structures" do
      config = File.join(@data_path, 'include-nested.yml')
      cfg = Collapsium::Config::Configuration.load_config(config)

      expect(cfg["foo"]).to eql "bar"
      expect(cfg["baz.quux"]).to eql "baz" # Overridden from include!
      expect(cfg["baz.config"]).to eql %w(foo bar)
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
