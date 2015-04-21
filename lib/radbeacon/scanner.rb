module Radbeacon
  class Scanner < LeScanner

    C_DEVICE_NAME = "0x0003"
    RADBEACON_USB = "52 61 64 42 65 61 63 6f 6e 20 55 53 42"

    def scan
      radbeacons = Array.new
      devices = super
      devices.each do |dev|
        radbeacon = radbeacon_check(dev)
        if radbeacon
          radbeacons << radbeacon
        end
      end
      radbeacons
    end

    def radbeacon_check(device)
      radbeacon = nil
      case device.values[C_DEVICE_NAME]
      when RADBEACON_USB
        radbeacon = Usb.new(device)
      end
      radbeacon
    end

  end
end
