# gvl\_timing

Measures timings for the current thread's GVL state for CRuby.

This will add some (small) overhead to all GVL activity, so may be better to
development/test or sampled use rather than continuous timing.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add gvl_timing

## Usage

```
>> timer = GVLTiming.measure { sleep 0.1 }
=> #<GVLTiming::Timer total=0.10s running=0.00s idle=0.10s stalled=0.00s>
>> timer.duration
=> 0.101082
>> timer.cpu_duration
=> 7.4667e-05
>> timer.idle_duration
=> 0.101048
>> timer.stalled_duration
=> 1.0e-06
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jhawthorn/gvl_timing. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/jhawthorn/gvl_timing/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the GvlTiming project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/jhawthorn/gvl_timing/blob/main/CODE_OF_CONDUCT.md).
