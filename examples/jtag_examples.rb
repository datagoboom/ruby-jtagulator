require_relative "../lib/jtagulator"

def continuous_identify
  jtag = Jtagulator::API::JTAG.new(port: "/dev/ttyUSB0", debug: true)
  jtag.start_session
  results = []
  ["DEFAULT", "IDCODE", "BYPASS", "RTCK"].each do |mode|
    puts jtag.identify(
      id_mode: mode,  # Optional, defaults to "DEFAULT" (j option)
      wait_limit: 30, # Optional, defaults to 120
      options: {
        start_pin: 0,
        end_pin: 9,
        bring_low: true, 
        low_time: 100, 
        high_time: 100,
       
        # You can optionally provide known pins for the BYPASS and RTCK modes
        # For RTCK, only provide the tck pin (others will be ignored)
       
        known_pins: {
        #  tdi: 0,
        #  tdo: 1,
          tck: 2,
        #  tms: 3
        }

      }
    )
  end 
end

continuous_identify