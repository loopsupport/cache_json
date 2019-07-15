RSpec.describe "CacheJSON validations" do

  class InvalidClass

    include CacheJSON::Base

    def compute_results(non_keyword_argument)
      non_keyword_argument + non_keyword_argument
    end
  end

  before do
    $redis = MockRedis.new
  end

  it "does not work without keyword arguments" do
    expect{InvalidClass.new.results(5)}.to raise_error ArgumentError, "Must use keyword arguments"
  end
end
