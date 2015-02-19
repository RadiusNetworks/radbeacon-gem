#!/usr/bin/env ruby

require 'open3'

class BluetoothLeDevice
  def initialize(mac_address)
    @mac_address = mac_address
  end

  def display
    puts "MAC Address: " + @mac_address
  end

  def con
    Open3.popen3("hciconfig") do |stdin, stdout, stderr, wait_thr|
      puts stdout.read
    end

    cmd = "gatttool -b #{@mac_address} --interactive"
    Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
      puts "Opened gatttool"
      puts "PID: #{wait_thr.pid}"
      stdin.puts "quit"
      stdin.close
      puts stdout.read
      stdout.close
      stderr.close

      #stdin.puts "connect"
    end
  end
end

class Radbeacon
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
  my_ble_device.con
end
