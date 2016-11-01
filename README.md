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
- Pathed access to configuration variables.
- Using the special `extends` configuration key, allows a configuration Hash
  to include all values from other configuration Hash(es).
- Using the special, top-level `include` configuration key, allows a
  configuration file to be split into multiple included files.
- As of `v0.2`, configuration files are [ERB templates](http://ruby-doc.org/stdlib-2.3.1/libdoc/erb/rdoc/ERB.html).
  Do your templating stuff as you'd usually do it.
- Allows overriding of configuration values from the environment.

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

## Pathed Access

Thanks to [collapsium](https://github.com/jfinkhaeuser/collapsium)'s `UberHash`,
configuration values can be accessed more easily than in a regular nested
structure. That is, the following are equivalent:

```ruby
config["foo"]["bar"]["baz"]
config["foo.bar.baz"]
config[".foo.bar.baz"]
config["foo.bar"]["baz"]
config["foo"]["bar.baz"]
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

## Environment Override

If the environment defines a variable named the same as a configuration
value path, transformed to upper case letters and with dot (`.`) separators
replaced by underscore (`_`), the environment variable value is used instead.

```ruby
# Called with FOO_BAR=42
config["foo.bar"] # => 42
```

Note that environment variables may contain `JSON` values, which will be parsed
appropriately, e.g. the following works:

```ruby
# Called with FOO_BAR='{ "baz": 42 }'
config["foo.bar.baz"] # => 42
```

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

## A Note on Priorities

A lot of the features above interact with each other. For example, environment
override still respects pathed access. In other cases, things are not quite
so clear, so let's give you a rough idea on priorities in the code:

1. Templating happens when files are loaded, and generates the most basic data
   the gem works with.
1. Configuration file merging happens next, i.e. `config.yml` and `config-local.yml`
   are merged into one data structure.
1. Next up is handling of `include` directives.
1. After that, `extends` is resolved - that is, `extends` works on paths that
   only exists after any of the above steps created them. This step finishes the
   configuration loading process.
1. Finally, environment override works whenever a value is *accessed*, meaning
   if the environment changes, so does the configuration value.
