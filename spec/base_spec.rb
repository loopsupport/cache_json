# frozen_string_literal: true

RSpec.describe CacheJSON::Base do
  # Hopefully these make sense for really fast/slow machines
  let!(:long_time) { 0.05 }
  let!(:short_time) { 0.001 }

  it 'actually computes the value the first time and uses the cache the second time' do
    result = execute_and_time { FindPrimes.new.results(prime_index: 500).last }
    expect(result[:value]).to eq(3571)
    expect(result[:seconds_elapsed]).to be > long_time
    expect(parsed_result('CacheJSON-FindPrimes-prime_index:500').last).to eq(3571)

    result = execute_and_time { FindPrimes.new.results(prime_index: 500).last }
    expect(result[:value]).to eq(3571)
    expect(result[:seconds_elapsed]).to be < short_time
  end

  it 'cache depends on arguments' do
    result = execute_and_time { FindPrimes.new.results(prime_index: 500).last }
    expect(result[:value]).to eq(3571)
    expect(result[:seconds_elapsed]).to be > long_time
    expect(parsed_result('CacheJSON-FindPrimes-prime_index:500').last).to eq(3571)
    expect(parsed_result('CacheJSON-FindPrimes-prime_index:999')).to eq(nil)

    result = execute_and_time { FindPrimes.new.results(prime_index: 499).last }
    expect(result[:value]).to eq(3559)
    expect(result[:seconds_elapsed]).to be > long_time
  end

  it 'clears the cache' do
    FindPrimes.new.results(prime_index: 100).last
    expect(parsed_result('CacheJSON-FindPrimes-prime_index:100').last).to eq(541)
    FindPrimes.new.clear_cache!
    expect(parsed_result('CacheJSON-FindPrimes-prime_index:100')).to eq(nil)
  end
end
