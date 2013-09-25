# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'palimpsest/version'

Gem::Specification.new do |spec|
  spec.name          = 'palimpsest'
  spec.version       = Palimpsest::VERSION
  spec.authors       = ['Evan Boyd Sosenko']
  spec.email         = ['razorx@evansosenko.com']
  spec.description   = %q{No web framework, no problem: Palimpsest gives any custom or legacy project a modern workflow and toolset.}
  spec.summary       = %q{Built flexible, simple, and customizable. Palimpsest runs on top of any project and acts as a post processor for your code. Features a Sprockets asset pipeline and easy integration with Kit.}
  spec.homepage      = 'https://github.com/razor-x/palimpsest'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'activesupport', '~> 4.0.0'
  spec.add_dependency 'archive-tar-minitar', '~> 0.5.2'
  spec.add_dependency 'grit', '~> 2.5.0'
  spec.add_dependency 'sprockets', '~> 2.10.0'

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake', '~> 10.1'
  spec.add_development_dependency 'bump', '~> 0.4'

  spec.add_development_dependency 'yard', '0.8.7.2'
  spec.add_development_dependency 'redcarpet', '3.0.0'
  spec.add_development_dependency 'github-markup', '0.7.5'

  spec.add_development_dependency 'rspec', '~> 2.14.1'
  spec.add_development_dependency 'fuubar', '~> 1.2.1'
  spec.add_development_dependency 'guard-rspec', '~> 3.1.0'
  spec.add_development_dependency 'guard-yard', '~> 2.1.0'
end
