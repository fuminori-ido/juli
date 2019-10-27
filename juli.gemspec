# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'juli/version'

Gem::Specification.new do |spec|
  spec.name          = "juli"
  spec.version       = Juli::VERSION
  spec.authors       = ["ido"]
  spec.email         = ["ido-gh@wtech.jp"]

  spec.summary       = %q{Offline wiki, and outline processor}
  spec.description   = %q{Offline wiki, and outline processor}
  spec.homepage      = "https://github.com/fuminori-ido/juli"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features|sample\/protected_photo)/}) } +
                       # generated by racc, should be in gem
                       %w(lib/juli/parser.tab.rb lib/juli/line_parser.tab.rb)
  spec.bindir        = 'bin'
  spec.executables   = 'juli'
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'aws-sdk-s3'
  spec.add_runtime_dependency 'i18n'
  spec.add_runtime_dependency 'rmagick'

  spec.add_development_dependency 'byebug'
  spec.add_development_dependency 'racc'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency 'rdoc'
  spec.add_development_dependency 'test-unit'
end
