# frozen_string_literal: true

RSpec.describe 'CacheJSON validations' do
  class BadClass
    include CacheJSON::Base

    def compute_results(non_keyword_argument)
      non_keyword_argument + non_keyword_argument
    end
  end

  class ClassWithoutArguments
    include CacheJSON::Base

    def compute_results
      'result'
    end
  end

  it 'does not work without keyword arguments' do
    expect { BadClass.new.results(5) }.to raise_error ArgumentError, 'Must use keyword arguments'
  end

  it 'works if there are no arguments provided' do
    expect(ClassWithoutArguments.new.results).to eq('result')
  end
end
