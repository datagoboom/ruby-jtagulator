module Jtagulator
  module API
    class Client
      attr_reader :port

      PARITY_OPTIONS = {
        "none" => SerialPort::NONE,
        "even" => SerialPort::EVEN,
        "odd" => SerialPort::ODD,
        "mark" => SerialPort::MARK,
        "space" => SerialPort::SPACE
      }.freeze

      def initialize(port: "/dev/ttyUSB0", baud: 115_200, data_bits: 8, stop_bits: 1, parity: "none", debug: false)
        log("Initializing UART")
        parity_sym = PARITY_OPTIONS[parity] || SerialPort::NONE
        @port = SerialPort.new(port, baud, data_bits, stop_bits, parity_sym)
        @debug = debug
      end

      def start_session
        log("Starting session")
        @port.flush_input
        @port.write(0x68)
        @port.read_timeout = 2000 # timeout in milliseconds
        res = safe_read
        if res == "NO_RESPONSE_LIMIT_REACHED" || res.inspect.to_s.length < 5
          log("Failed to start session, attempting to restart", error: true)
          @port.write("\x04") # ctrl+d
          sleep 1
          start_session
        end
      end

      def safe_read(wait_limit: 3)
        reading = false
        wait_time = 0
        begin
          @port.read_nonblock(1024)
        rescue IO::WaitReadable
          log("Waiting for response from board...") unless reading
          sleep 0.1
          reading = true
          wait_time += 0.1
          if wait_time > wait_limit
            log("No response after #{wait_limit} seconds", error: true)
            return "NO_RESPONSE_LIMIT_REACHED"
          end
          retry
        end
      end

      def set_mode(mode)
        log("Attempting to go to main menu")
        go_to_main_menu
        log("Setting device mode")
        map = {
          "j" => "JTAG",
          "u" => "UART",
          "g" => "GPIO",
          "s" => "SWD"
        }
        begin
          @port.write(mode + "\r")
          sleep 1
        rescue Errno::EIO
          sleep 0.1
          retry
        end
        begin
          res = @port.read_nonblock(1024) # attempt to read up to 1024 bytes non-blocking
          res = res.inspect.to_s.gsub('\r', "\r").gsub('\n', "\n")
        rescue IO::WaitReadable
          sleep 0.1
          retry
        end

        unless res.include?(map[mode])
          log(res, error: true)
          send_key("m") 
          set_mode(mode) 
        end
      end

      def go_to_main_menu
        3.times do
          send_key("m")
          sleep 0.25
        end
      end

      def send_key(key)
        @port.write("#{key}\r")
        res = safe_read
        log(res)
        if res == ("?\r\r\n") || res.include?("Value out of range!")
          return false 
        else
          return true
        end
      end

      def log(message, error: false)
        timestamp = Time.now.strftime("[%H:%M:%S]")
        if @debug
          if error
            print timestamp
            puts "[ERROR]  " + message
          else
            if message.include? "\r\r\n"
              prev_input = message.split("\r\r\n")[0]
              print timestamp
              puts "[INPUT]  " + prev_input
              msgs = message.split("\r\r\n")[1].split("\r\n")
              msgs.each do |msg|
                print timestamp
                puts "[OUTPUT] " + msg.gsub("\r", "").gsub("\n", "")
              end
            else
              print timestamp
              puts "[LOG]    " + message
            end
          end
        end
      end

      def collect_results_until_complete
        results = []
        until (response = safe_read).include?("complete")
          result = response.strip
          results << result unless result == "-" || result.empty?
          log(response)
        end
        results
      end
    end
  end
end
