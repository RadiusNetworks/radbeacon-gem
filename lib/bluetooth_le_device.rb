require 'pty'
require 'expect'

class BluetoothLeDevice
  attr_reader :mac_address, :name, :is_connectable, :characteristics, :values, :errors

  TIMEOUT = 0.5

  def initialize(mac_address, name)
    self.errors = []
    self.mac_address = mac_address
    self.name = name
    self.is_connectable = false
    self.characteristics = Array.new
    self.values = Hash.new
  end

  def display
    puts "MAC Address: " + self.mac_address + " Name: " + self.name + " Can connect: " + self.is_connectable.to_s
  end

  def fetch_characteristics
    result = false
    if self.can_connect?
      self.is_connectable = true
      if self.discover_characteristics
        if self.char_values
          result = true
        end
      end
    end
    result
  end

  def can_connect?
    @errors = []
    result = false
    cmd = "gatttool -b #{self.mac_address} --interactive"
    PTY.spawn(cmd) do |output, input, pid|
      output.expect(/\[LE\]>/)
      input.puts "connect"
      if output.expect(/Connection successful/, TIMEOUT)
        self.is_connectable = true
        result = true
      else
        @errors << "Connection failed"
      end
      input.puts "quit"
    end
    result
  end

  def discover_characteristics
    @errors = []
    result = false
    output = ""
    cmd = "gatttool -b #{self.mac_address} --characteristics 2>&1"
    output = `#{cmd}`
    if output.strip != "Discover all characteristics failed: Internal application error: I/O"
      self.characteristics = []
      output.each_line do |line|
        result = line.scan(/^handle = (0x[a-f0-9]{4}), char properties = (0x[a-f0-9]{2}), char value handle = (0x[a-f0-9]{4}), uuid = ([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})$/)
        if !result.empty?
          characteristic = {"handle" => result[0][0], "properties" => result[0][1], "value_handle" => result[0][2], "uuid" => result[0][3]}
          self.characteristics << characteristic
        end
      end
      result = true
    else
      @errors << "Discover characteristics failed"
    end
    result
  end

  def char_values
    @errors = []
    result = false
    cmd = "gatttool -b #{self.mac_address} --interactive"
    if self.characteristics != []
      PTY.spawn(cmd) do |output, input, pid|
        output.expect(/\[LE\]>/)
        input.puts "connect"
        if output.expect(/Connection successful/, TIMEOUT)
          self.characteristics.each do |char|
            input.puts "char-read-hnd #{char['value_handle']}"
            if output.expect(/Characteristic value\/descriptor: /, TIMEOUT)
              value = output.expect(/^[0-9a-f\s]+\n/, TIMEOUT)
              self.values[char['value_handle']] = value.first.strip
            end
          end
          result = true
        else
          @errors << "Fetch characteristic values failed"
        end
        input.puts "quit"
      end
    else
      @errors << "No characteristics present"
    end
    result
  end

  private

  attr_writer :mac_address, :name, :is_connectable, :characteristics, :values, :errors

end
