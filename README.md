# Ruby JTAGulator

This is a simple ruby wrapper around the [JTAGulator](https://www.crowdsupply.com/grand-idea-studio/jtagulator) from [Grand Idea Studio](https://www.grandideastudio.com/). It is intended to be used as a library for automating hardware assessment using the JTAGulator. Currently, it only supports the following features:

- UART
  - Identify UART Pinout
  - UART Passthrough
- JTAG
  - Identify JTAG Pinout (Default Mode)
  - Identify JTAG pinout (IDCODE Scan)
  - Identify JTAG pinout (BYPASS Scan)
  - Identify RTCK (adaptive clocking)

More to come. 


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'jtagulator'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install jtagulator

## Usage

Check out the examples folder for basic usage.


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/datagoboom/jtagulator. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/jtagulator/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Jtagulator project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/jtagulator/blob/master/CODE_OF_CONDUCT.md).

