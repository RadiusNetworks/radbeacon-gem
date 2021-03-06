require 'pty'
require 'expect'
require 'timeout'

module Radbeacon
  class BluetoothLeDevice
    attr_reader :mac_address, :name, :is_connectable, :characteristics, :values, :errors

    TIMEOUT = 0.5

    def initialize(mac_address, name)
      @errors = []
      @mac_address = mac_address
      @name = name
      @is_connectable = false
      @characteristics = Array.new
      @values = Hash.new
    end

    def display
      puts "MAC Address: " + @mac_address + " Name: " + @name + " Can connect: " + @is_connectable.to_s
    end

    def fetch_characteristics
      result = false
      if self.can_connect?
        @is_connectable = true
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
      cmd = "gatttool -b #{@mac_address} --interactive"
      PTY.spawn(cmd) do |output, input, pid|
        output.expect(/\[LE\]>/)
        input.puts "connect"
        if output.expect(/Connection successful/, TIMEOUT)
          @is_connectable = true
          result = true
        else
          @errors << "Connection failed"
        end
        input.puts "quit"
      end
      result
    end

    def characteristics_command
      success = true
      output = nil
      rout, wout = IO.pipe
      rerr, werr = IO.pipe
      characteristics_command_str = "gatttool -b #{@mac_address} --characteristics"
      pid = Process.spawn(characteristics_command_str, :out => wout, :err => werr)
      begin
        Timeout.timeout(5) do
          Process.wait(pid)
        end
      rescue Timeout::Error
        Process.kill('TERM', pid)
        success = false
      end
      wout.close
      werr.close
      stdout = rout.readlines.join("")
      stderr = rerr.readlines.join("")
      rout.close
      rerr.close
      if success
        output = [stdout, stderr].join("")
      end
      output
    end

    def discover_characteristics
      @errors = []
      result = false
      output = characteristics_command
      if output && output.strip != "Discover all characteristics failed: Internal application error: I/O"
        @characteristics = []
        output.each_line do |line|
          result = line.scan(/^handle = (0x[a-f0-9]{4}), char properties = (0x[a-f0-9]{2}), char value handle = (0x[a-f0-9]{4}), uuid = ([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})$/)
          if !result.empty?
            characteristic = {"handle" => result[0][0], "properties" => result[0][1], "value_handle" => result[0][2], "uuid" => result[0][3]}
            @characteristics << characteristic
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
      cmd = "gatttool -b #{@mac_address} --interactive"
      if @characteristics != []
        PTY.spawn(cmd) do |output, input, pid|
          output.expect(/\[LE\]>/)
          input.puts "connect"
          if output.expect(/Connection successful/, TIMEOUT)
            @characteristics.each do |char|
              input.puts "char-read-hnd #{char['value_handle']}"
              if output.expect(/Characteristic value\/descriptor: /, TIMEOUT)
                if value = output.expect(/^[0-9a-f\s]+\n/, TIMEOUT)
                  @values[char['value_handle']] = value.first.strip
                end
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

  protected

    attr_writer :mac_address, :name, :is_connectable, :characteristics, :values, :errors

  end
end
