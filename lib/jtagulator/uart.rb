# frozen_string_literal: true

module Jtagulator
  module API
    class UART
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

      def identify(wait_limit: 120, options: {})
        @client.set_mode("u")
        @client.log("Identifying UART pins")
        configure_identify(options)

        response = @client.safe_read(wait_limit: wait_limit)

        results = collect_results_until_complete
        parsed_results = parse_results(results)

        @client.log("UART pin identification complete")
        @client.log("No results, is the target connected?", error: true) if results == []
        parsed_results
      end

      def start_passthrough(options: {})
        @client.set_mode("u")
        @client.log("Starting UART passthrough")
        configure_passthrough(options)
      end

      def send_command(command)
        @client.send_key(command)
        response = @client.safe_read
        return "No response, timeout reached" if response == "NO_RESPONSE_LIMIT_REACHED"
      end

      def stop_passthrough
        @client.log("Stopping UART passthrough")
        @port.write("\x18") # ctrl+x
      end

      private

      def configure_identify(options)
        default_options = {
          voltage: 1.5,
          start_pin: 0,
          end_pin: 1,
          known_pins: false,
          output_str: "\r",
          delay: 50,
          ignore_non_printable: false,
          bring_low: false,
          low_time: 100,
          high_time: 100
        }

        options = default_options.merge(options)

        keys = [
          "v", 
          options[:voltage].to_s, 
          "u",
          options[:start_pin].to_s, 
          options[:end_pin].to_s, "n",
          options[:output_str], 
          options[:delay].to_s, 
          options[:ignore_non_printable] ? "y" : "n",
          options[:bring_low] ? "y" : "n"
        ]

        keys.push(options[:low_time].to_s, options[:high_time].to_s) if options[:bring_low]
        keys.each do |key|
          @client.send_key(key)
        end
        @port.write(" ")
      end

      def configure_passthrough(options)
        default_options = {
          voltage: 1.5,
          baud: 115_200,
          tx_pin: 0,
          rx_pin: 1,
          local_echo: false
        }

        options = default_options.merge(options)

        keys = [
          "v", 
          options[:voltage].to_s, 
          "p", 
          options[:tx_pin].to_s, 
          options[:rx_pin].to_s, 
          options[:baud].to_s, 
          options[:local_echo] ? "y" : "n"
        ]

        keys.each do |key|
          @client.send_key(key)
        end
      end

      def collect_results_until_complete
        results = []
        until (response = @client.safe_read).include?("complete")
          result = response.strip
          results << result unless result == "-" || result.empty?
          @client.log(response)
        end
        results
      end

      def parse_results(results)
        parsed_data = []
        current_data = {}

        results.each do |result|
          result.split("\r\n").each do |line|
            if txd_match = line.match(/TXD: (\d+)/)
              current_data[:txd] = txd_match[1]
            end

            if rxd_match = line.match(/RXD: (\d+)/)
              current_data[:rxd] = rxd_match[1]
            end

            if baud_match = line.match(/Baud: (\d+)/)
              if current_data.key?(:baud)
                parsed_data.push(current_data)
                current_data = { txd: current_data[:txd], rxd: current_data[:rxd], baud: baud_match[1] }
              else
                current_data[:baud] = baud_match[1]
              end
            end

            next unless data_match = line.match(/\[ ([A-F0-9\s]+) \]/)

            data_obj = {
              raw: data_match[1].split(" ").map { |x| x.to_i(16) },
              ascii: data_match[1].split(" ").map { |x| x.to_i(16) }.map { |x| hex_to_ascii(x) }.join
            }
            current_data[:data] = data_obj
          end
        end

        parsed_data.push(current_data) if current_data.key?(:Baud)

        parsed_data
      end

      def hex_to_ascii(hex)
        if hex >= 32 && hex <= 126
          hex.chr
        else
          "."
        end
      end
    end
  end
end
