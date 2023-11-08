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
        @port.read_timeout = 5000 # timeout in milliseconds
        res = safe_read
        if res == "NO_RESPONSE_LIMIT_REACHED" || res.inspect.to_s.length < 5
          log("Failed to start session, attempting to restart", error: true)
          @port.write("\x04") # ctrl+d
          sleep 1
          start_session
        end
      end

      def safe_read(wait_limit: 5)
        reading = false
        wait_time = 0
        begin
          @port.read_nonblock(1024)
        rescue IO::WaitReadable
          log("Waiting for data") unless reading
          sleep 0.1
          reading = true
          wait_time += 0.1
          if wait_time > wait_limit
            log("No response after #{wait_limit} seconds, you may need to manually restart device", error: true)
            return "NO_RESPONSE_LIMIT_REACHED"
          end
          retry
        end
      end

      def set_mode(mode)
        log("Setting device mode")
        map = {
          "j" => "JTAG",
          "u" => "UART",
          "g" => "GPIO",
          "s" => "SWD"
        }
        begin
          @port.write(mode + "\r")
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
        set_mode(mode) unless res.include?(map[mode])
      end

      def send_key(key)
        @port.write("#{key}\r")
        log(safe_read)
      end

      def log(message, error: false)
        timestamp = Time.now.strftime("[%H:%M:%S]")
        if @debug
          if error
            print timestamp.light_red
            puts "[ERROR]  ".light_red + message.light_red
          else
            if message.include? "\r\r\n"
              prev_input = message.split("\r\r\n")[0]
              print timestamp.light_yellow
              puts "[INPUT]  ".light_yellow + prev_input.light_yellow
              msgs = message.split("\r\r\n")[1].split("\r\n")
              msgs.each do |msg|
                print timestamp.light_blue
                puts "[OUTPUT] ".light_blue + msg.gsub("\r", "").gsub("\n", "").light_blue
              end
            else
              print timestamp.light_black
              puts "[LOG]    ".light_black + message.light_black
            end
          end
        end
      end
    end
  end
end
