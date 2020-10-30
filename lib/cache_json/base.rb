# frozen_string_literal: true

require 'cache_json/adapters/redis'

module CacheJSON
  module Base
    def self.included(base)
      base.extend(ClassMethods)
    end

    def results(args = {})
      raise ArgumentError, 'Must use keyword arguments' unless args.is_a?(Hash)

      options = self.class.cache_json_full_options
      cache = Cache.new(args: args, options: options)
      check_cache(args: args, cache: cache) ||
        JSON.parse(refresh_cache!(args: args, cache: cache).to_json) # stringify keys
    end

    def cache_expiring_soon?(args:, cache: nil)
      cache ||= Cache.new(args: args, options: self.class.cache_json_full_options)
      cache.cache_expiring_soon?
    end

    def clear_cache!
      Cache.new(options: self.class.cache_json_full_options).clear_cache!
    end

    def refresh_cache!(args:, cache: nil)
      cache ||= Cache.new(args: args, options: self.class.cache_json_full_options)
      results = compute_results(**args)
      cache.cached_results = results
      results
    end

    def check_cache(args:, cache: nil)
      cache ||= Cache.new(args: args, options: self.class.cache_json_full_options)
      cache.cached_results
    end

    class Cache
      attr_accessor :args
      attr_accessor :options

      def initialize(args: {}, options:)
        @args = args
        @options = options
      end

      def cached_results
        adapter.cached_results
      end

      def cached_results=(results)
        adapter.cached_results = results
      end

      def clear_cache!
        adapter.clear_cache!
      end

      def cache_expiring_soon?
        adapter.cache_expiring_soon?
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
        CacheJSON::Config.options.merge(cache_json_class_specific_overrides).merge(class_name: to_s)
      end
    end
  end
end
