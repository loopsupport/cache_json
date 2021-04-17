# frozen_string_literal: true

begin
  require 'sidekiq'
rescue LoadError
  nil
end
module CacheJSON
  class Worker
    if defined?(Sidekiq)
      include Sidekiq::Worker
      sidekiq_options queue: 'cache_json'
    else
      def perform_async(*)
        raise 'Sidekiq gem not found. ' \
              'You can still call this worker manually via CacheJSON::Worker.new.perform'
      end
    end

    def perform(params="{}")
      parsed_params = JSON.parse(params)
      klass = parsed_params["klass"]
      args = (parsed_params["args"] || {}).transform_keys(&:to_sym)
      if klass
        klass = Object.const_get(klass)
        klass.new.refresh_cache!(args: args) if should_refresh?(klass, args)
      else
        AllPermutations.new.results.each do |perm|
          if should_refresh?(perm[:klass], perm[:args])
            perm[:klass] = perm[:klass].to_s
            CacheJSON::Worker.perform_async(perm.to_json)
          end
        end
      end
    end

    private

    def should_refresh?(klass, args)
      !klass.new.check_cache(args: args) || klass.new.cache_expiring_soon?(args: args)
    end

    class AllPermutations
      def results
        all_cache_classes.flat_map do |klass|
          all_argument_permutations(klass).map do |args|
            {
              klass: klass,
              args: args
            }
          end
        end
      end

      def all_cache_classes
        # TODO: make this more efficient
        ObjectSpace.each_object(Class).select do |klass|
          klass.included_modules.include? CacheJSON::Base
        end
      end

      def all_argument_permutations(klass)
        refresh_options = klass.cache_json_full_options[:refresh]
        if refresh_options
          all_combinations_with_fixed_points({}, refresh_options[:arguments])
        else
          []
        end
      end

      def all_combinations_with_fixed_points(fixed_points, full_hash)
        non_fixed_points = full_hash.dup.delete_if { |k, _| fixed_points.key?(k) }
        if non_fixed_points.empty?
          [fixed_points]
        else
          pivot_key = non_fixed_points.keys.first
          values_for_key(non_fixed_points, pivot_key).flat_map do |pivot_key_value|
            new_fixed_points = fixed_points.merge(Hash[pivot_key, pivot_key_value])
            all_combinations_with_fixed_points(new_fixed_points, full_hash)
          end
        end
      end

      def values_for_key(hsh, key)
        pivot_key_values = hsh[key]
        if pivot_key_values.is_a?(Proc)
          pivot_key_values.call
        elsif pivot_key_values.is_a?(Range) || pivot_key_values.is_a?(Array)
          pivot_key_values
        else
          [pivot_key_values]
        end
      end
    end
  end
end
