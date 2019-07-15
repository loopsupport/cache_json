# frozen_string_literal: true

class Example
  include CacheJSON::Base
  cache_json_options(
    time_to_expire: 60 * 60,
    refresh: {
      arguments: {
        first: (5..10),
        second: ['one option', 'another option'],
        third: 'the only option'
      }
    }
  )

  def compute_results(first:, second:, third:)
    first.to_s + second.to_s + third.to_s
  end
end

RSpec.describe CacheJSON::Worker do
  let!(:expected_keys) do
    (5..10).flat_map do |first|
      ['one option', 'another option'].flat_map do |second|
        "CacheJSON-Example-first:#{first}-second:#{second}-third:the only option"
      end
    end + ['CacheJSON-Example']
  end

  before do
    CacheJSON::Worker.new.perform
  end

  it 'refreshes all the permutations of arguments' do
    expect($redis.keys.sort).to eq(expected_keys.sort)
  end

  # We check this by setting some keys, waiting a bit,
  # then refreshing and waiting until the older keys expire
  context 'only refreshes missing keys' do
    let!(:first_key) { 'CacheJSON-Example-first:5-second:another option-third:the only option' }
    let!(:second_key) { 'CacheJSON-Example-first:10-second:one option-third:the only option' }

    before do
      $redis.del(first_key)
      $redis.del(second_key)
      Timecop.travel(DateTime.now + 1800 * second)
      CacheJSON::Worker.new.perform
      Timecop.travel(DateTime.now + 1800 * second)
    end

    it do
      expect($redis.keys.sort).to eq(['CacheJSON-Example', first_key, second_key].sort)
    end
  end
end
