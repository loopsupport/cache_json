RSpec.describe CacheJSON::Base do

  before do
    $redis = MockRedis.new
  end

  it "actually computes the value the first time and uses the cache the second time" do
    result = execute_and_time{FindPrimes.new.results(prime_index: 1000).last}
    expect(result[:value]).to eq(7919)
    expect(result[:seconds_elapsed]).to be > 0.1
    expect(parsed_result("CacheJSON-FindPrimes-prime_index:1000").last).to eq(7919)

    result = execute_and_time{FindPrimes.new.results(prime_index: 1000).last}
    expect(result[:value]).to eq(7919)
    expect(result[:seconds_elapsed]).to be < 0.001
  end

  it "cache depends on arguments" do
    result = execute_and_time{FindPrimes.new.results(prime_index: 1000).last}
    expect(result[:value]).to eq(7919)
    expect(result[:seconds_elapsed]).to be > 0.1
    expect(parsed_result("CacheJSON-FindPrimes-prime_index:1000").last).to eq(7919)
    expect(parsed_result("CacheJSON-FindPrimes-prime_index:999")).to eq(nil)

    result = execute_and_time{FindPrimes.new.results(prime_index: 999).last}
    expect(result[:value]).to eq(7907)
    expect(result[:seconds_elapsed]).to be > 0.1
  end

  it "clears the cache" do
    FindPrimes.new.results(prime_index: 100).last
    expect(parsed_result("CacheJSON-FindPrimes-prime_index:100").last).to eq(541)
    FindPrimes.new.clear_cache!
    expect(parsed_result("CacheJSON-FindPrimes-prime_index:100")).to eq(nil)
  end
end
