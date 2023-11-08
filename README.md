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

First off, you should probably become familiar with [what the JTAGulator can do](https://github.com/grandideastudio/jtagulator/wiki). 

To perform UART pin discovery:

```ruby
require 'jtagulator'

# Debug mode outputs a ton of live interaction data, omit this param (or set to false) to turn it off
uart = Jtagulator::API::UART.new(port: "/dev/ttyUSB0", debug: true)

# Starts the live session with the Jtagulator hardware
uart.start_session

# Collects results of scan
res = uart.identify(
        wait_limit: 30, # optional, default timeout is 120s for pin discovery
        # here are all of the available options, none of them are required to operate
        options: {
          voltage: 1.5,
          start_pin: 0,
          end_pin: 1,
          known_pins: false,
          output_str: "\\x0D",
          delay: 10,
          ignore_non_printable: false,
          bring_low: false,
          low_time: 100,
          high_time: 100
        }
      ).to_s.green

# returns (if found):
# {
#  "txd" => 0,
#  "rxd" => 1,
#  "baud": 115200,
#  "data": {
#    "raw": [0x0A, 0x0D],
#    "ascii": ".."
#  }
#} 
```

For more info, check out the examples folder.


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/datagoboom/jtagulator. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/jtagulator/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Jtagulator project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/jtagulator/blob/master/CODE_OF_CONDUCT.md).

