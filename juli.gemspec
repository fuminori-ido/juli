# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'juli/version'

Gem::Specification.new do |spec|
  spec.name          = "juli"
  spec.version       = Juli::VERSION
  spec.authors       = ["ido"]
  spec.email         = ["fuminori_ido@yahoo.co.jp"]

  spec.summary       = %q{Offline wiki, and idea processor}
  spec.description   = %q{Offline wiki, and idea processor}
  spec.homepage      = "https://github.com/fuminori-ido/juli"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'racc'
  spec.add_runtime_dependency 'simplecov'
  spec.add_runtime_dependency 'RMagick'

  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake", "~> 10.0"
end
