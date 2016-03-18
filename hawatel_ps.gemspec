# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hawatel_ps/version'

Gem::Specification.new do |spec|
  spec.name          = "hawatel_ps"
  spec.version       = HawatelPS::VERSION
  spec.authors       = ['Przemyslaw Mantaj','Daniel Iwaniuk']
  spec.email         = ['przemyslaw.mantaj@hawatel.com', 'daniel.iwaniuk@hawatel.com']

  spec.summary       = "Ruby gem for retrieving information about running processes"
  spec.description   = %q{HawatelPS (hawatel_ps) is a Ruby gem for retrieving information about running processes. It is easy to use and you can get useful information about a process.
                          You can terminate, suspend, resume and check status of the process on Linxu platform. On Windows platform you can terminate and check state of the process.}
  spec.homepage      = "http://github.com/hawatel/hawatel_ps"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 1.9'

  spec.add_development_dependency "factory_girl"
  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "codeclimate-test-reporter"
end
