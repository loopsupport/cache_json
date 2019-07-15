module CacheJSON::Adapters
  class Redis
    attr_accessor :args
    attr_accessor :options

    def initialize(args:, options:)
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
      $redis.sadd(class_key, full_key)
      $redis.set(full_key, results.to_json)
      $redis.expire(full_key, options[:time_to_expire].to_i)
    end

    def clear_cache!
      $redis.smembers(class_key).each do |key|
        $redis.del(key)
      end
      $redis.del(class_key)
    end

    private

      def full_key
        @full_key ||= "#{class_key}-#{arguments_signature}"
      end

      def class_key
        @class_key ||= "CacheJSON-#{options[:class_name]}"
      end

      def arguments_signature
        args.to_a.sort_by do |row|
          row[0]
        end.map do |row|
          "#{row[0]}:#{row[1]}"
        end.join("-")
      end
  end
end