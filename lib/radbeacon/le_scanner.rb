module Radbeacon

  class LeScanner
    attr_accessor :duration

    def initialize(duration = 5)
      @duration = duration
    end

    def scan_command
      rout, wout = IO.pipe
      scan_command_str = "sudo hcitool lescan"
      pid = Process.spawn(scan_command_str, :out => wout)
      begin
        Timeout.timeout(@duration) do
          Process.wait(pid)
        end
      rescue Timeout::Error
        Process.kill('TERM', pid)
      end
      wout.close
      scan_output = rout.readlines.join("")
      rout.close
      scan_output
    end

    def passive_scan
      devices = Array.new
      scan_output = self.scan_command
      scan_output.each_line do |line|
        result = line.scan(/^([A-F0-9:]{15}[A-F0-9]{2}) (.*)$/)
        if !result.empty?
          mac_address = result[0][0]
          name = result[0][1]
          if !devices.find {|s| s.mac_address == mac_address}
            device = BluetoothLeDevice.new(mac_address, name)
            devices << device
          end
        end
      end
      devices
    end

    def scan
      devices = self.passive_scan
      devices.each do |dev|
        dev.fetch_characteristics
      end
      devices
    end

  end
end
