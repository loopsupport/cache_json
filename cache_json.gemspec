# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cache_json/version'

Gem::Specification.new do |spec|
  spec.name          = 'cache_json'
  spec.version       = CacheJSON::VERSION
  spec.authors       = ['Paul Gut']
  spec.email         = ['paul@loopsupport.com']

  spec.summary       = 'Extremely simple Redis caching for any Ruby class'
  spec.description   = 'Extremely simple Redis caching for any Ruby class'
  spec.homepage      = 'https://github.com/loopsupport/cache_json'
  spec.license       = 'MIT'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/loopsupport/cache_json'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'redis', '>= 3.3.5', '< 5'
  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'mock_redis', '~> 0.21.0'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0.72'
  spec.add_development_dependency 'sidekiq', '>= 3.0', '< 7'
  spec.add_development_dependency 'timecop', '~> 0.9.1'
end
