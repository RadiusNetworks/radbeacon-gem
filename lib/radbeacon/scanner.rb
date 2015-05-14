module Radbeacon
  class Scanner < LeScanner

    C_DEVICE_NAME = "0x0003"
    RADBEACON_USB = "52 61 64 42 65 61 63 6f 6e 20 55 53 42"

    def scan
      devices = super
      radbeacons = devices.map { |dev| radbeacon_check(dev) }
      radbeacons.compact
    end

    def fetch(mac_address)
      dev = BluetoothLeDevice.new(mac_address, nil)
      radbeacon_check(dev) if dev.fetch_characteristics
    end

    def radbeacon_check(device)
      radbeacon = nil
      case device.values[C_DEVICE_NAME]
      when RADBEACON_USB
        radbeacon = Usb.create_if_valid(device)
      end
      radbeacon
    end

  end
end
