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

## Configuration File Management

### Configuration File Location

The friendly neighbour to the `#config` function introduced in the basic
usage section above is the `#config_file` accessor. Its value will default
to `config.yml`, but you can set it to something different, too:

```ruby
config_file = 'foo.yaml'
puts config["foo"] # loaded automatically from foo.yaml
```

### Loading Configuration Files

All that `#config` and `#config_file` do is wrap `#load_config` such that
configuration is loaded only once. You can load configuration files manually,
too:

```ruby
my_config = Collapsium::Config::Configuration.load_config('filename.yaml')
```

### Array Files

Configuration files can also contain Arrays at the top level. While that may
make some sense at times, it does not make for good naming schemes and creates
problems elsewhere.

Therefore, if your file contains an Array at the top level, the class wraps it
into a Hash with a `config` key containing the Array:

```yaml
- foo
- bar
```

```ruby
config["config"][0] # => "foo"
config["config"][1] # => "bar"
```

### File Formats

The gem supports loading [YAML](http://yaml.org/) and [JSON](http://www.json.org/)
configuration files. Both formats can be mixed in the various mechanisms described
below.

### Local Configuration Overrides

For the example file of `config/config.yml`, if a file with the same path and
name, and the name postfix `-local` exists (i.e. `config/config-local.yml`), that
file will also be loaded. It's keys will be recursively added to the keys from the
main configuration file, overwriting only leaves, not entire hashes.

Example:

```yaml
# config/config.yml
---
foo:
  bar: 42
  baz: quux

# config/config-local.yml
---
something: else
foo:
  baz: override

# result
---
something: else
foo:
  bar: 42
  baz: override
```

### Templating

Configuration files aren't quite static entities even taking merging of local
overrides into account. They can further be generated at load time by
templating, extension and including.

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

But even without explicit passing of a data hash, you can use templating to
e.g. include environment variables:

```erb
foo: <%= ENV['MYVAR'] %>
```

Note, though, that this might interact unexpectedly with the environment
override feature described later.


### Extension

An additional feature is that you can extend individual hashes with values from
other hashes.

```yaml
---
root:
  foo: bar
derived:
  baz: quux
  extends: root
```

This results in:

```yaml
---
root:
  foo: bar
derived:
  baz: quux
  foo: bar
  base: root
```

The special `extends` keyword is interpreted to merge all values from
the value at path `.root` into the value at path `.derived`. Additionally,
`.derived` will gain a new key `base` which is an Array containing all the
bases merged into the value.

**Notes:**

- Absolute paths are preferred for values of `extends`.
- Relative paths for values of `extends` are looked up in the parent of the
  value that contains the `extends` keyword, i.e. the root in the example
  above. So in this minimal example, specifying `.base` and `base` is
  equivalent.
- You can specify a comma-separated list of bases in the `extends` keyword.
  Latter paths overwrite values in earlier paths.
- You can also specify an Array of paths, with the same effect.
- This feature means that `extends` and `base` are reserved configuration keys!
- Multiple levels of extension are supported.

### Includes

Includes work just as you might expect: if you specify a key `include` anywhere,
the value will be interpreted as a file system path to another configuration file.
That other file will be loaded, and the parent of the `include` statement will
gain all the values from the other configuration file.

Example:

```yaml
# config/main.yml
include: config/first.yml
foo:
  bar: 42
  include: config/second.yml
```

```yaml
# config/first.yml
baz: quux
```

```yaml
# config/second.yml
- 123
- 456
```

Will result in:

```yaml
# final YAML
baz: quux
foo:
  bar: 42
  data:
    - 123
    - 456
```

**Notes:**

- If your loaded configuration file contains an Array at the top level, then
  a new key `config` will be added (see Array Files above)
- You can specify a comma-separated list of paths in the `include` keyword.
  Latter paths overwrite values in earlier paths.
- You can also specify an Array of paths, with the same effect.
- This means that `include` is a reserved configuration key.

## Configuration Access

### Pathed Access

Thanks to [collapsium](https://github.com/jfinkhaeuser/collapsium)'s `UberHash`,
configuration values can be accessed more easily than in a regular nested
structure. Take the following configuration as an example:

```yaml
---
foo:
  bar:
    baz: 42
    quux:
      - 123
      - "asdf"
```

Then, the following are equivalent:

```ruby
config["foo"]["bar"]["baz"]
config["foo.bar.baz"]
config[".foo.bar.baz"]
config["foo.bar"]["baz"]
config["foo"]["bar.baz"]
```

The major benefit is that if *any* of the path components does not exist, nil is
returned (and the behaviour is equivalent to other access methods such as
`:fetch`, etc.)

Similarly you can use this type of access for writing: `config['baz.quux'] = 42`
will create both the `baz` hash, and it's child the `quux` key.

## Environment Override

Given a configuration path, any environment variable with the same name (change
path to upper case letters and replace `.` with `_`, e.g. `foo.bar` becomes
`FOO_BAR`) overrides the values in the configuration file.

```ruby
# Called with FOO_BAR=42
config["foo.bar"] # => 42
```

If the environment variable is parseable as JSON, then that parsed JSON will
**replace** the original configuration path (i.e. it will not be merged).

```ruby
# Called with FOO_BAR='{ "baz": 42 }'
config["foo.bar.baz"] # => 42
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
