# Cache JSON

This gem lets you easily cache the results of any computation to Redis. The cache is automatically populated when the `results` method is called.

The cache expires after a specified time, unless you explicitly clear it before that. You can use the provided Sidekiq job to periodically refresh the cache.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'cache_json'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cache_json

## Usage

All you need is a class with a `compute_results` method (make sure you use keyword arguments):

```ruby
class ExpensiveJob

  include CacheJSON::Base

  cache_json_options(
    time_to_expire: 1.hour, # Specify how long the cache lives
  )

  def compute_results(first_arg:, second_arg:)
    # Compute some stuff and return the results
    # The results will then be cached *for those specific arguments*
  end
end

# If the cache exists, return it. Otherwise, populate it and return it
ExpensiveJob.new.results(first_arg: "foo", second_arg: "bar")

# Clear the cache for all arguments
ExpensiveJob.new.clear_cache!
```

If you'd like to specify some global defaults, you can put them in `config/initializers/cache_json.rb`

```ruby
CacheJSON.configure do |config|
  config.time_to_expire = 6.hours
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/loopsupport/cache_json. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the CacheJSON project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/loopsupport/cache_json/blob/master/CODE_OF_CONDUCT.md).
