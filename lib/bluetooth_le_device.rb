require 'pty'
require 'expect'

class BluetoothLeDevice
  attr_accessor :mac_address, :name, :is_connectable, :characteristics, :values

  def initialize(mac_address, name)
    self.mac_address = mac_address
    self.name = name
    self.is_connectable = false
    self.characteristics = Array.new
    self.values = Hash.new
    if self.can_connect?
      self.is_connectable = true
      self.discover_characteristics
      self.char_values
    end
  end

  def display
    puts "MAC Address: " + self.mac_address + " Name: " + self.name + " Can connect: " + self.is_connectable.to_s
  end

  def can_connect?
    result = false
    timeout = 0.5
    cmd = "gatttool -b #{self.mac_address} --interactive"
    PTY.spawn(cmd) do |output, input, pid|
      output.expect(/\[LE\]>/)
      input.puts "connect"
      if output.expect(/Connection successful/, timeout)
        self.is_connectable = true
        result = true
      end
      input.puts "quit"
    end
    result
  end

  def discover_characteristics
    output = ""
    cmd = "gatttool -b #{self.mac_address} --characteristics"
    output = `#{cmd}`
    output.each_line do |line|
      result = line.scan(/^handle = (0x[a-f0-9]{4}), char properties = (0x[a-f0-9]{2}), char value handle = (0x[a-f0-9]{4}), uuid = ([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})$/)
      if !result.empty?
        characteristic = {"handle" => result[0][0], "properties" => result[0][1], "value_handle" => result[0][2], "uuid" => result[0][3]}
        self.characteristics << characteristic
      end
    end
    self.characteristics
  end

  def char_values
    timeout = 0.5
    cmd = "gatttool -b #{self.mac_address} --interactive"
    PTY.spawn(cmd) do |output, input, pid|
      output.expect(/\[LE\]>/)
      input.puts "connect"
      if output.expect(/Connection successful/, timeout)
         self.characteristics.each do |char|
            input.puts "char-read-hnd #{char['value_handle']}"
            if output.expect(/Characteristic value\/descriptor: /, timeout)
              value = output.expect(/^[0-9a-f\s]+\n/, timeout)
              self.values[char['value_handle']] = value.first.strip
            end
         end
      end
      input.puts "quit"
    end
  end
end
