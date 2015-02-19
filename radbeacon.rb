#!/usr/bin/env ruby

require 'timeout'
require 'pty'
require 'expect'

class BluetoothLeDevice

  ## Define gatt characteristic constants
  # Generic Access Profile
  C_DEVICE_NAME = '0x0003'
  C_APPEARANCE = '0x0006'
  # Device Information
  C_MANUFACTURER_NAME = '0x000a'
  C_MODEL_NUMBER = '0x000d'
  C_SERIAL_STRING = '0x0010'
  C_FIRMWARE_STRING = '0x0013'
  # Configuration
  GATT_DEV_MODEL = "0x0017"
  GATT_DEV_ID = "0x001a"
  GATT_DEV_NAME = "0x001d"
  GATT_UUID = "0x0020"
  GATT_MAJOR = "0x0023"
  GATT_MINOR = "0x0026"
  GATT_POWER = "0x0029"
  GATT_TXPOWER = "0x002c"
  GATT_INTERVAL = "0x002f"
  GATT_RESULT = "0x0032"
  GATT_NEW_PIN = "0x0035"
  GATT_ACTION = "0x0038"
  GATT_PIN = "0x003b"
  GATT_BCTYPE = "0x003e"
  GATT_FWVERSION = "0x0041"
  GATT_CONN_TIMEOUT = "0x0044"
  GATT_BEACON_SWITCH  = "0x0047"


  def initialize(mac_address)
    @mac_address = mac_address
  end

  def display
    puts "MAC Address: " + @mac_address
  end

  def con(beacon)
    puts beacon.name
    write_commands = ["#{GATT_DEV_NAME} 4a616d65732773205465737420426561636f6e",
      "#{GATT_UUID} 842af9c408f511e39282f23c91aec05e", "#{GATT_MAJOR} 0001",
      "#{GATT_MINOR} 0002", "#{GATT_POWER} be", "#{GATT_TXPOWER} 0f",
      "#{GATT_INTERVAL} 8000", "#{GATT_ACTION} 00000001", "#{GATT_PIN} 30303030"]
    timeout = 20
    cmd = "gatttool -b #{@mac_address} --interactive"
    PTY.spawn(cmd) do |output, input, pid|
      output.expect(/\[LE\]>/)
      input.puts "connect"
      output.expect(/Connection successful/)
      write_commands.each do |cmd|
        cmd = "char-write-req #{cmd}"
        puts "~~~> #{cmd}"
        input.puts cmd
        output.expect(/Characteristic value was written successfully/, timeout)
      end
      input.puts "char-read-hnd 0x32"
      output.expect(/Characteristic value\/descriptor: 00 00 00 00/) do
        puts "Update Success"
      end
      input.puts "quit"
      _, status = Process.waitpid2(pid)
      if status.success?
        puts "Yay!"
      else
        puts "Boo :-("
      end
    end
  end
end

class Radbeacon
  attr_accessor :name, :uuid, :major, :minor, :power, :tx_power, :adv_interval, :pin
  def initialize(name, uuid, major, minor, power, tx_power, adv_interval, pin)
    @name = name
    @uuid = uuid
    @major = major
    @minor = minor
    @power = power
    @tx_power = tx_power
    @adv_interval = adv_interval
    @pin = pin
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
  my_beacon = Radbeacon.new('RadBeacon USB', '2F234454-CF6D-4A0F-ADF2-F4911BA9FFA6', '1', '1', '-66', '0x0f', '0x8000', '0000')
  #my_beacon.display

  my_ble_device = BluetoothLeDevice.new('00:07:80:15:74:5B')
  my_ble_device.display
  my_ble_device.con(my_beacon)
end
