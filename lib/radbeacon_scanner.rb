require_relative 'le_scanner'

class RadbeaconScanner < LeScanner

  RADBEACON_USB = "52 61 64 42 65 61 63 6f 6e 20 55 53 42"

  def scan
    radbeacons = Array.new
    devices = super
    devices.each do |dev|
      radbeacon = radbeacon_check(dev)
      if radbeacon
        puts "Device is a RadBeacon USB"
        radbeacons << radbeacon
      end
    end
    radbeacons
  end

  def radbeacon_check(device)
    radbeacon = nil
    case device.values['0x0003']
    when RADBEACON_USB
      radbeacon = RadbeaconUsb.new(device)
    end
    radbeacon
  end

end
