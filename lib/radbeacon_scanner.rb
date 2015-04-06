require 'le_scanner'

class RadbeaconScanner

  def radbeacon_scan(duration = 5)
    radbeacons = Array.new
    devices = self.scan(duration)
    devices.each do |device|
      if device.can_connect?
        device.is_connectable = true
        if device.is_radbeacon?
          device.is_radbeacon = true
          radbeacons << device
        end
      end
    end
    radbeacons
  end

end
