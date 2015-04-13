require_relative 'bluetooth_le_device'

class LeScanner
  attr_accessor :uuid, :duration, :results, :scan

  def initialize(duration = 5)
    self.duration = duration
  end

  def scan
    devices = Array.new
    scan_output = `sudo hcitool lescan & sleep #{self.duration}; sudo kill -2 $!`
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

end
