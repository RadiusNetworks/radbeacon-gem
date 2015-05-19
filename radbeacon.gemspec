# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'radbeacon/version'

Gem::Specification.new do |spec|
  spec.name          = "radbeacon"
  spec.version       = Radbeacon::VERSION
  spec.authors       = ["Radius Networks"]
  spec.email         = ["support@radiusnetworks.com"]

  spec.summary       = %q{Provides RadBeacon (BLE Proximity Beacon) scanning and configuring capabilities on a linux machine.}
  spec.homepage      = "http://www.radiusnetworks.com"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.2"

end
