module CacheJSON::Base
  def self.included(base)
    base.extend(ClassMethods)
  end

  def results(args)
    options = self.class.cache_json_full_options
    cache = Cache.new(args: args, options: options)
    if cache.get_cached_results
      # Rails.logger.info "Got #{self.class} results from cache" if options[:logging_enabled]
      cache.get_cached_results
    else
      # Rails.logger.info "Generating #{self.class} cached results" if options[:logging_enabled]
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
      return @get_cached_results if @get_cached_results

      results_json = $redis.get(full_key)
      if results_json
        @get_cached_results = JSON.parse(results_json)
      end
    end

    def set_cached_results(results)
      $redis.set(full_key, results.to_json)
      $redis.expire(full_key, options[:time_to_expire].to_i)
    end

    def clear_cache!
      $redis.keys.select do |key|
        key.include?(base_key)
      end.each do |key|
        # Rails.logger.info "Deleting #{self.class} cached results" if options[:logging_enabled]
        $redis.del(key)
      end
    end

    def full_key
      @full_key ||= "#{base_key}-#{arguments_signature}"
    end

    def base_key
      @base_key ||= "CacheJSON-#{options[:class_name]}"
    end

    def arguments_signature
      args.to_a.sort_by do |row|
        row[0]
      end.map do |row|
        "#{row[0]}:#{row[1]}"
      end.join("-")
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