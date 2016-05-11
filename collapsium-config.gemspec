# coding: utf-8
#
# collapsium-config
# https://github.com/jfinkhaeuser/collapsium-config
#
# Copyright (c) 2016 Jens Finkhaeuser and other collapsium-config contributors.
# All rights reserved.
#

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'collapsium-config/version'

# rubocop:disable Style/UnneededPercentQ
# rubocop:disable Style/SpaceAroundOperators
Gem::Specification.new do |spec|
  spec.name          = "collapsium-config"
  spec.version       = Collapsium::Config::VERSION
  spec.authors       = ["Jens Finkhaeuser"]
  spec.email         = ["jens@finkhaeuser.de"]
  spec.description   = %q(
        FIXME
  )
  spec.summary       = %q(
        FIXME
  )
  spec.homepage      = "https://github.com/jfinkhaeuser/collapsium-config"
  spec.license       = "MITNFA"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.0'

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rubocop", "~> 0.40"
  spec.add_development_dependency "rake", "~> 11.1"
  spec.add_development_dependency "rspec", "~> 3.4"
  spec.add_development_dependency "simplecov", "~> 0.11"
  spec.add_development_dependency "yard", "~> 0.8"

  spec.add_dependency 'collapsium', '~> 0.1'
end
# rubocop:enable Style/SpaceAroundOperators
# rubocop:enable Style/UnneededPercentQ
