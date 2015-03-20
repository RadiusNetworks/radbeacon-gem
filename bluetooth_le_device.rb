require 'timeout'
require 'pty'
require 'expect'
require 'le_scanner'

class BluetoothLeDevice

  def self.scan(duration = 5)
    LeScanner.new.scan(duration)
  end

  attr_accessor :mac_address, :name, :characteristics, :is_connectable
  def initialize(mac_address, name)
    @mac_address = mac_address
    @name = name
    @is_connectable = false
    @characteristics = Hash.new
  end

  def display
    puts "MAC Address: " + @mac_address + " Name: " + @name + " Can connect: " + @is_connectable.to_s
  end

  def can_connect?
    result = false
    timeout = 1
    cmd = "gatttool -b #{@mac_address} --interactive"
    PTY.spawn(cmd) do |output, input, pid|
      output.expect(/\[LE\]>/)
      input.puts "connect"
      if output.expect(/Connection successful/, timeout)
        @is_connectable = true
        result = true
      end
      input.puts "quit"
    end
    result
  end

  def characteristics
    timeout = 1
    cmd = "gatttool -b #{@mac_address} --interactive"
    PTY.spawn(cmd) do |output, input, pid|
      output.expect(/\[LE\]>/)
      input.puts "connect"
      if output.expect(/Connection successful/, timeout)
        puts "Discovering characteristics..."
        input.puts "characteristics"
        output.each_line do |line|
          puts line
        end
      end
      input.puts "quit"
    end
    characteristics
  end
end
