require "cache_json/adapters/redis"

module CacheJSON::Base
  def self.included(base)
    base.extend(ClassMethods)
  end

  def results(args)
    raise ArgumentError, "Must use keyword arguments" unless args.kind_of?(Hash)
    options = self.class.cache_json_full_options
    cache = Cache.new(args: args, options: options)
    if cache.get_cached_results
      cache.get_cached_results
    else
      results = compute_results(args)
      cache.set_cached_results(results)
      JSON.parse(results.to_json) # stringify keys
    end
  end

  def clear_cache!
    Cache.new(options: self.class.cache_json_full_options).clear_cache!
  end

  class Cache
    attr_accessor :args
    attr_accessor :options

    def initialize(args: {}, options:)
      @args = args
      @options = options
    end

    def get_cached_results
      adapter.get_cached_results
    end

    def set_cached_results(results)
      adapter.set_cached_results(results)
    end

    def clear_cache!
      adapter.clear_cache!
    end

    def adapter
      @adapter ||= CacheJSON::Adapters::Redis.new(args: args, options: options)
    end
  end

  module ClassMethods
    # Setter
    def cache_json_options(options_hash)
      cache_json_class_specific_overrides.merge!(options_hash)
    end

    # Just the class-specific overrides
    def cache_json_class_specific_overrides
      @cache_json_class_specific_overrides ||= {}
    end

    # Getter (inherits from global defaults)
    def cache_json_full_options
      CacheJSON::Config.options.merge(cache_json_class_specific_overrides).merge(class_name: self.to_s)
    end
  end
end