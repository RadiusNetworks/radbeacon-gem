require 'bluetooth_le_device'

class RadbeaconUsb extends BluetoothLeDevice

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


  def is_radbeacon?
    result = false
    timeout = 0.5
    cmd = "gatttool -b #{@mac_address} --interactive"
    PTY.spawn(cmd) do |output, input, pid|
      output.expect(/\[LE\]>/)
      input.puts "connect"
      if output.expect(/Connection successful/, timeout)
        input.puts "char-read-hnd 0x0003"
        if output.expect(/Characteristic value\/descriptor: 52 61 64 42 65 61 63 6f 6e 20 55 53 42/, timeout)
          result = true
        end
      end
      input.puts "quit"
    end
    result
  end

end
