# frozen_string_literal: true

class Example
  include CacheJSON::Base
  cache_json_options(
    time_to_expire: 60 * 60,
    refresh: {
      arguments: {
        first: (5..10),
        second: ['one option', 'another option'],
        third: 'the only option',
        fourth: -> { ['proc result'] }
      }
    }
  )

  def compute_results(first:, second:, third:, fourth:)
    first.to_s + second.to_s + third.to_s + fourth.to_s
  end
end

RSpec.describe CacheJSON::Worker do
  let!(:expected_keys) do
    (5..10).flat_map do |first|
      ['one option', 'another option'].flat_map do |second|
        "CacheJSON-Example-first:#{first}-fourth:proc result-second:#{second}-third:the only option"
      end
    end + ['CacheJSON-Example']
  end
  let(:relevant_keys) { $redis.keys.select { |k| k.include?('CacheJSON-Example') }.sort }

  before do
    CacheJSON::Worker.new.perform
  end

  it 'refreshes all the permutations of arguments' do
    expect(relevant_keys).to eq(expected_keys.sort)
  end

  # We check this by setting some keys, waiting a bit,
  # then refreshing and waiting until the older keys expire
  context 'only refreshes missing keys' do
    let!(:first_key) do
      'CacheJSON-Example-first:5-fourth:proc result-second:' \
        'another option-third:the only option'
    end
    let!(:second_key) do
      'CacheJSON-Example-first:10-fourth:proc result-second:one option-third:the only option'
    end

    before do
      $redis.del(first_key)
      $redis.del(second_key)
      Timecop.travel(DateTime.now + 3595 * second)
      CacheJSON::Worker.new.perform
      Timecop.travel(DateTime.now + 1000 * second)
    end

    it do
      expect(relevant_keys).to eq(['CacheJSON-Example', first_key, second_key].sort)
    end
  end
end
