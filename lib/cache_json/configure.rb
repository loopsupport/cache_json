module CacheJSON

  class Config
    @time_to_expire = 3600 # 1 hour

    def self.options
      {
        time_to_expire: time_to_expire
      }
    end

    class << self
      attr_accessor :time_to_expire
    end
  end

  def self.configure
    yield(CacheJSON::Config) if block_given?
  end
end