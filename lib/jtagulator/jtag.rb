module Jtagulator
  module API
    class JTAG
      def initialize(port: "/dev/ttyUSB0", baud: 115_200, data_bits: 8, stop_bits: 1, parity: "none", debug: false)
        @client = Jtagulator::API::Client.new(
          port: port,
          baud: baud,
          data_bits: data_bits,
          stop_bits: stop_bits,
          parity: parity,
          debug: debug
        )
        @port = @client.port
      end

      def start_session
        @client.start_session
      end

      def identify(id_mode: "DEFAULT", wait_limit: 120, options: {})
        @client.set_mode("j")
        @client.log("Identifying JTAG pins, mode: #{id_mode}")
        configure_identify(id_mode, wait_limit, options)
      end

      def configure_identify(id_mode, wait_limit, options)
        default_options = {
          voltage: 1.5,
          start_pin: 0,
          end_pin: 6,
          bring_low: false,
          low_time: 100,
          high_time: 100
        }

        options = default_options.merge(options)

        modes = {
          "DEFAULT" => "j",
          "IDCODE" => "i",
          "BYPASS" => "b",
          "RTCK" => "r"
        }

        keys = []

        base_keys = [
          "v",
          options[:voltage].to_s,
          modes[id_mode],
          options[:start_pin].to_s,
          options[:end_pin].to_s
        ]

        timing_keys = [
          options[:low_time].to_s,
          options[:high_time].to_s
        ]

        if id_mode == "BYPASS"
          known = false 
          known_pins = options[:known_pins]
          if known_pins
            known_pins.each do |k, v|
              if v.to_i > 0 && v.to_i < 23
                known = true
              end
            end
            if known 
              # Say yes to "Are any pins already known?"
              base_keys.push("y")

              # Pins that are unknown will be set to x
              pins = {
                tdi: "x",
                tdo: "x",
                tck: "x",
                tms: "x",
              }

              # Adding known pins to pin list
              pins.merge!(options[:known_pins]) if options[:known_pins]

              pins.each do |k, v|
                # Add pin definitions as answers
                base_keys.push(v)
              end
            end 
          else
            # Say no to "Are any pins already known?"
            base_keys.push("n")
          end
          
        elsif id_mode == "RTCK"
          known = false 
          known_pins = options[:known_pins]
          if known_pins
            known = true if known_pins[:tck].to_i > 0 && known_pins[:tck].to_i < 23
            if known 
              # Say yes to "Is TCK already known?"
              base_keys.push("y")
              # Add pin definition as answer
              base_keys.push(known_pins[:tck].to_s)
            end 
          end
        end

        if options[:bring_low]
          base_keys.push("y")
          keys = base_keys + timing_keys
        else
          base_keys.push("n")
          keys = base_keys
        end

        keys.each do |key|
          @client.send_key(key)
        end
        @port.write(" ")
      end
    end
  end
end

