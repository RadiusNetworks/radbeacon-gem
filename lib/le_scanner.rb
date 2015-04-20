require_relative 'bluetooth_le_device'

class LeScanner
  attr_accessor :duration

  def initialize(duration = 5)
    @duration = duration
  end

  def passive_scan
    devices = Array.new
    scan_output = `sudo hcitool lescan & sleep #{@duration}; sudo kill -2 $!`
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
