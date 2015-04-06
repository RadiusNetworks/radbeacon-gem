class LeScanner

  def scan(duration = 5)
    devices = Array.new
    scan_output = `sudo hcitool lescan & sleep #{duration}; sudo kill -2 $!`
    scan_output.each_line do |line|
      result = line.scan(/^([A-F0-9:]{15}[A-F0-9]{2}) (.*)$/)
      if !result.empty?
        device = BluetoothLeDevice.new(result[0][0], result[0][1])
        if !devices.find {|s| s.mac_address == device.mac_address}
          devices << device
        end
      end
    end
    devices
  end

end
