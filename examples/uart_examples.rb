require "colorize"
require "jtagulator"

def continuous_identify
  uart = Jtagulator::API::UART.new(port: "/dev/ttyUSB0", debug: true)
  uart.start_session
  results = []
  while true 
    puts uart.identify(
      wait_limit: 30,
      options: { 
        bring_low: true, 
        low_time: 100, 
        high_time: 100,
        start_pin: 0,
        end_pin: 1,
        output_str: "\\x0D"
      }
    ).to_s.green
  end 
end 

def passthrough_test
  uart = Jtagulator::API::UART.new(port: "/dev/ttyUSB0", debug: true)
  uart.start_session
  uart.start_passthrough
  res = uart.send_command("1\n")
  puts res
  uart.stop_passthrough
end

continuous_identify