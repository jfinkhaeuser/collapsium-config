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
  to include all values from other configuration Hash(es).
- Using the special, top-level `include` configuration key, allows a
  configuration file to be split into multiple included files.
- As of `v0.2`, configuration files are [ERB templates](http://ruby-doc.org/stdlib-2.3.1/libdoc/erb/rdoc/ERB.html).
  Do your templating stuff as you'd usually do it.

# Basic Usage

While you can use the `Configuration` class yourself, the simplest usage is to
access a global configuration object:

```ruby
require 'collapsium-config'
include Collapsium::Config

puts config["foo"] # loaded automatically from config.yml
```

# Advanced Usage

## Configuration File Location

The friendly neighbour to the `#config` function introduced in the basic
usage section above is the `#config_file` accessor. Its value will default
to `config.yml`, but you can set it to something different, too:

```ruby
config_file = 'foo.yaml'
puts config["foo"] # loaded automatically from foo.yaml
```

## Loading Configuration Files

All that `#config` and `#config_file` do is wrap `#load_config` such that
configuration is loaded only once. You can load configuration files manually,
too:

```ruby
my_config = Collapsium::Config::Configuration.load_config('filename.yaml')
```

## Extension

Given the following configuration file:

```yaml
base:
  foo: 42

derived:
  bar: value
  extends: .base
```

Then the special `extends` keyword is interpreted to merge all values from
the value at path `.base` into the value at path `.derived`. Additionally,
`.derived` will gain a new key `base` which is an Array containing all the
bases merged into the value.

- Absolute paths are preferred for values of `extends`.
- Relative paths for values of `extends` are looked up in the parent of the
  value that contains the `extends` keyword, i.e. the root in the example
  above. So in this minimal example, specifying `.base` and `base` is
  equivalent.
- You can specify a comma-separated list of bases in the `extends` keyword.
  Latter paths overwrite values in earlier paths.

## Templating

ERB templating in configuration files works out-of-the-box, but one of the
more powerful features is of course to substitute some values in the template
which your loading code already knows. If you're using `#load_config`, you
can do that with the `data` keyword parameter:

```ruby
my_data_hash = {}
my_config = Configuration.load_config('foo.yaml', data: my_data_hash)
```

Note that the template has access to the entire hash under the `data` name,
not to its individual keys:

```erb
<%= data[:some_key] %> # correct usage
<%= some_key %>        # incorrect usage
```
