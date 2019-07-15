# frozen_string_literal: true

require 'timecop'

RSpec.describe 'CacheJSON.configure' do
  let!(:second) { 1.0 / 24 / 60 / 60 }

  before do
    $redis = MockRedis.new
  end

  context 'time_to_expire' do
    def set_app_default
      CacheJSON.configure do |config|
        config.time_to_expire = 200
      end
    end

    def set_class_specific
      FindPrimes.class_eval do
        cache_json_options(
          time_to_expire: 100
        )
      end
    end

    def set_cache
      FindPrimes.new.results(prime_index: 100)
    end

    def cache_exists?
      parsed_result('CacheJSON-FindPrimes-prime_index:100') != nil
    end

    context 'gem default' do
      before do
        set_cache
      end

      it do
        expect(cache_exists?).to be(true)
        Timecop.travel(DateTime.now + 3599.9 * second)
        expect(cache_exists?).to be(true)
        sleep 0.1
        expect(cache_exists?).to be(false)
      end
    end

    context 'app default' do
      before do
        set_app_default
        set_cache
      end

      it do
        expect(cache_exists?).to be(true)
        Timecop.travel(DateTime.now + 199.9 * second)
        expect(cache_exists?).to be(true)
        sleep 0.1
        expect(cache_exists?).to be(false)
      end
    end

    context 'class specific' do
      before do
        set_app_default
        set_class_specific
        set_cache
      end

      it do
        expect(cache_exists?).to be(true)
        Timecop.travel(DateTime.now + 99.9 * second)
        expect(cache_exists?).to be(true)
        sleep 0.1
        expect(cache_exists?).to be(false)
      end
    end
  end
end
