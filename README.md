# collapsium-config

Using [collapsium](https://github.com/jfinkhaeuser/collapsium)'s `UberHash`
class for easy access to configuration values, this gem reads and merges
various configuration sources into one configuration object.


[![Gem Version](https://badge.fury.io/rb/collapsium-config.svg)](https://badge.fury.io/rb/collapsium-config)
[![Build status](https://travis-ci.org/jfinkhaeuser/collapsium-config.svg?branch=master)](https://travis-ci.org/jfinkhaeuser/collapsium-config)
[![Code Climate](https://codeclimate.com/github/jfinkhaeuser/collapsium-config/badges/gpa.svg)](https://codeclimate.com/github/jfinkhaeuser/collapsium-config)
[![Test Coverage](https://codeclimate.com/github/jfinkhaeuser/collapsium-config/badges/coverage.svg)](https://codeclimate.com/github/jfinkhaeuser/collapsium-config/coverage)

# Functionality

- Supports [JSON](http://www.json.org/) and [YAML](http://yaml.org/) file
  formats.
- Given a main configuration file `foo.yml` to load, also loads `foo-local.yml`
  if that exists, and merges it's contents recursively into the main
  configuration.
- Using the special `extends` configuration key, allows a configuration Hash
  to include all values from another configuration Hash.
- Using the special, top-level `include` configuration key, allows a
  configuration file to be split into multiple included files.
