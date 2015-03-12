#!/usr/bin/env ruby

require 'timeout'
require 'pty'
require 'expect'

class LeScanner

  def scan(duration)
    devices = Array.new
    scan_output = `sudo hcitool lescan & sleep #{duration}; sudo kill -2 $!`
    scan_output.each_line do |line|
      result = line.scan(/^([A-F0-9:]{15}[A-F0-9]{2}) (.*)$/)
      if !result.empty?
        device = BluetoothLeDevice.new(result[0][0], result[0][1])
        devices << device
      end
    end
    devices
  end

  def radbeacon_scan(duration)
    connectable_devices = Array.new
    devices = self.scan(duration)
    devices.each do |device|
      if device.can_connect?
        device.is_connectable = true
        connectable_devices << device
      end
    end
    connectable_devices
  end

end

class BluetoothLeDevice

  ## Define GATT characteristic constants
  # Generic Access Profile
  C_DEVICE_NAME = '0x0003'
  C_APPEARANCE  = '0x0006'
  # Device Information
  C_MANUFACTURER_NAME = '0x000a'
  C_MODEL_NUMBER      = '0x000d'
  C_SERIAL_STRING     = '0x0010'
  C_FIRMWARE_STRING   = '0x0013'
  # Configuration
  GATT_DEV_MODEL     = "0x0017"
  GATT_DEV_ID        = "0x001a"
  GATT_DEV_NAME      = "0x001d"
  GATT_UUID          = "0x0020"
  GATT_MAJOR         = "0x0023"
  GATT_MINOR         = "0x0026"
  GATT_POWER         = "0x0029"
  GATT_TXPOWER       = "0x002c"
  GATT_INTERVAL      = "0x002f"
  GATT_RESULT        = "0x0032"
  GATT_NEW_PIN       = "0x0035"
  GATT_ACTION        = "0x0038"
  GATT_PIN           = "0x003b"
  GATT_BCTYPE        = "0x003e"
  GATT_FWVERSION     = "0x0041"
  GATT_CONN_TIMEOUT  = "0x0044"
  GATT_BEACON_SWITCH = "0x0047"

  ## Define GATT action/result constants
  # Actions
  GATT_ACTION_DONOTHING        = "00000000"
  GATT_ACTION_UPDATE_ADV       = "00000001"
  GATT_ACTION_UPDATE_PIN       = "00000002"
  GATT_ACTION_FACTORY_RESET    = "00000003"
  GATT_ACTION_DFU              = "00000004"
  GATT_ACTION_LOCK             = "00000005"
  GATT_ACTION_CONNECTABLE_TIME = "00000006"
  # Results
  GATT_SUCCES      = "00000000"
  GATT_INVALID_PIN = "00000001"
  GATT_ERROR       = "00000002" #not used

  ## Transmit power and advertisement frequency values
  TRANSMIT_POWER_VALUES = {"-23" => "00", "-21" => "01", "-18" => "03", "-14" => "05",
    "-11" => "07", "-7" => "09", "-4" => "0b", "+0" => "0d", "+3" => "0f"}
  MEASURED_POWER_VALUES = ["-94", "-92", "-90", "-86", "-84", "-79", "-74", "-72", "-66"]
  ADVERTISING_RATE_VALUES = {"2" => "E002", "4" => "5001", "6" => "E000", "8" => "9000", "10" => "6000",
    "12" => "5000", "14" => "3500", "16" => "3000", "18" => "2500", "20" => "2000"}

  attr_accessor :mac_address, :name, :is_connectable, :is_radbeacon
  def initialize(mac_address, name)
    @mac_address = mac_address
    @name = name
    @is_connectable = false
    @is_radbeacon = false
  end

  def display
    puts "MAC Address: " + @mac_address + " Name: " + @name + " Can connect: " + @is_connectable.to_s
  end

  def update_params(beacon)
    update_params_commands = ["#{GATT_DEV_NAME} #{beacon.name_to_bytes}",
      "#{GATT_UUID} #{beacon.uuid_to_bytes}", "#{GATT_MAJOR} #{beacon.major_to_bytes}",
      "#{GATT_MINOR} #{beacon.minor_to_bytes}", "#{GATT_POWER} #{beacon.power_to_bytes}", "#{GATT_TXPOWER} 0f",
      "#{GATT_INTERVAL} 8000", "#{GATT_ACTION} #{GATT_ACTION_UPDATE_ADV}", "#{GATT_PIN} #{beacon.pin_to_bytes}"]
      result = con(update_params_commands)
  end

  def update_pin(beacon)
    update_pin_commands = ["#{GATT_NEW_PIN} #{beacon.new_pin_to_bytes}", "#{GATT_ACTION} #{GATT_ACTION_UPDATE_PIN}", "#{GATT_PIN} #{beacon.pin_to_bytes}"]
    result = con(update_pin_commands)
  end

  def factory_reset(beacon)
    reset_commands = ["#{GATT_ACTION} #{GATT_ACTION_FACTORY_RESET}", "#{GATT_PIN} #{beacon.pin_to_bytes}"]
    result = con(reset_commands)
  end

  def boot_to_dfu(beacon)
    dfu_commands = ["#{GATT_ACTION} #{GATT_ACTION_DFU}", "#{GATT_PIN} #{beacon.pin_to_bytes}"]
    result = con(dfu_commands)
  end

  def lock(beacon)
    lock_commands = ["#{GATT_ACTION} #{GATT_ACTION_LOCK}", "#{GATT_PIN} #{beacon.pin_to_bytes}"]
    result = con(lock_commands)
  end

  def con(commands)
    result = false
    timeout = 5
    cmd = "gatttool -b #{@mac_address} --interactive"
    PTY.spawn(cmd) do |output, input, pid|
      output.expect(/\[LE\]>/)
      input.puts "connect"
      output.expect(/Connection successful/, timeout)
      commands.each do |cmd|
        cmd = "char-write-req #{cmd}"
        puts "~~~> #{cmd}"
        input.puts cmd
        output.expect(/Characteristic value was written successfully/, timeout)
      end
      input.puts "char-read-hnd 0x32"
      output.expect(/Characteristic value\/descriptor: 00 00 00 00/, timeout) do
        result = true
      end
      input.puts "quit"
      _, status = Process.waitpid2(pid)
      if status.success?
        puts "Yay!"
      else
        puts "Boo :-("
      end
    end
    result
  end

  def can_connect?
    result = false
    timeout = 0.5
    cmd = "gatttool -b #{@mac_address} --interactive"
    PTY.spawn(cmd) do |output, input, pid|
      output.expect(/\[LE\]>/)
      input.puts "connect"
      if output.expect(/Connection successful/, timeout)
        result = true
      end
      input.puts "quit"
    end
    result
  end
end

class Radbeacon
  attr_accessor :name, :uuid, :major, :minor, :power, :tx_power, :adv_interval, :pin, :new_pin
  def initialize(name, uuid, major, minor, power, tx_power, adv_interval, pin, new_pin)
    @name = name
    @uuid = uuid
    @major = major
    @minor = minor
    @power = power
    @tx_power = tx_power
    @adv_interval = adv_interval
    @pin = pin
    @new_pin = new_pin
  end

  def name_to_bytes
    bytes = self.name.unpack('H*')[0]
  end

  def uuid_to_bytes
    if self.uuid.match(/^[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}$/)
      bytes = self.uuid.gsub(/-/, '')
    else
      bytes = nil
    end
  end

  def major_to_bytes
    if self.major.to_i.between?(0, 65535)
      bytes = sprintf("%04x", self.major.to_i)
    else
      bytes = nil
    end
  end

  def minor_to_bytes
    if self.minor.to_i.between?(0, 65535)
      bytes = sprintf("%04x", self.minor.to_i)
    else
      bytes = nil
    end
  end

  def power_to_bytes
    if self.power.to_i.between?(-127, -1)
      bytes = sprintf("%x", self.power.to_i + 256)
    else
      bytes = nil
    end
  end

  def pin_to_bytes
    if self.pin.match(/^[0-9]{4}$/)
      bytes = self.pin.unpack('H*')[0]
    else
      puts "Invalid PIN"
      bytes = nil
    end
  end

  def new_pin_to_bytes
    if self.new_pin.match(/^[0-9]{4}$/)
      bytes = self.new_pin.unpack('H*')[0]
    else
      puts "Invalid PIN"
      bytes = nil
    end
  end

  def display
    puts "Name: " + @name
    puts "UUID: " + @uuid
    puts "Major: " + @major
    puts "Minor: " + @minor
    puts "Power: " + @power
  end
end

if __FILE__ == $0
  def do_actions
    my_beacon = Radbeacon.new('James\'s Test Beacon', '842AF9C4-08F5-11E3-9282-F23C91AEC05E', '707', '707', '-66', '0x0f', '0x8000', '0000', '1234')
    my_other_beacon = Radbeacon.new('James\'s Test Beacon', '842AF9C4-08F5-11E3-9282-F23C91AEC05E', '707', '707', '-66', '0x0f', '0x8000', '1234', '0000')
    #my_beacon.display

    my_ble_device = BluetoothLeDevice.new('00:07:80:15:74:5B', 'RadBeacon USB')
    my_ble_device.display

    puts "Updating PIN..."
    if my_ble_device.update_pin(my_beacon)
      puts "Update PIN Success!"
    end
    puts "Factory Reset..."
    if my_ble_device.factory_reset(my_other_beacon)
      puts "Factory Reset Success!"
    end
    puts "Updating Params..."
    if my_ble_device.update_params(my_beacon)
      puts "Update Params Success!"
    end
    puts "Booting to DFU..."
    if my_ble_device.boot_to_dfu(my_beacon)
      puts "Boot to DFU Success!"
    end
    puts "Locking..."
    if my_ble_device.lock(my_beacon)
      puts "Lock Success!"
    end
  end

  #do_actions
  devices = LeScanner.new.scan(1)
  puts "Discovered " + devices.count.to_s + " BLE devices"
  connectable_devices = LeScanner.new.radbeacon_scan(1)
  puts "Discovered " + connectable_devices.count.to_s + " connectable BLE devices"

  #puts devices.inspect

  #my_ble_device = BluetoothLeDevice.new('00:07:80:15:74:5B', 'RadBeacon USB')
  #puts "My BLE device can connect? --> " + my_ble_device.is_connectable.to_s

end
