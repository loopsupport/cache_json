# frozen_string_literal: true

require 'bundler/setup'
require 'cache_json'
require 'mock_redis'
require 'timecop'

# Finds the nth prime the most inefficient way possible
class FindPrimes
  include CacheJSON::Base

  def compute_results(prime_index:)
    primes = []
    i = 1
    while primes.length < prime_index
      i += 1
      primes << i if is_prime?(i)
    end
    primes
  end

  private

  def is_prime?(index)
    (2..index - 1).select do |k|
      index % k == 0
    end.empty?
  end
end

def execute_and_time
  start_time = Time.now
  result = yield
  end_time = Time.now
  {
    seconds_elapsed: (end_time - start_time),
    value: result
  }
end

def second
  1.0 / 24 / 60 / 60
end

def parsed_result(key)
  unparsed_result = $redis.get(key)
  unparsed_result ? JSON.parse(unparsed_result) : nil
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  config.before(:each) do
    $redis = MockRedis.new
    $redis.flushdb
  end

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
