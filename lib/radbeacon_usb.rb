require_relative 'bluetooth_le_device'
require_relative 'radbeacon_utils'

class RadbeaconUsb < BluetoothLeDevice

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

  attr_reader :mac_address, :errors, :dev_model, :dev_id, :dev_version
  attr_accessor :dev_name, :uuid, :major, :minor, :power, :tx_power, :adv_interval

  def initialize(device)
    self.errors = []
    self.mac_address = device.mac_address
    self.dev_model = RadbeaconUtils.bytes_to_text(device.values[GATT_DEV_MODEL])
    self.dev_id =  RadbeaconUtils.bytes_to_text(device.values[GATT_DEV_ID])
    self.dev_version =  RadbeaconUtils.bytes_to_text(device.values[GATT_FWVERSION])
    self.dev_name =  RadbeaconUtils.bytes_to_text(device.values[GATT_DEV_NAME])
    self.uuid =  RadbeaconUtils.bytes_to_uuid(device.values[GATT_UUID])
    self.major =  RadbeaconUtils.bytes_to_major_minor(device.values[GATT_MAJOR])
    self.minor = RadbeaconUtils.bytes_to_major_minor(device.values[GATT_MINOR])
    self.power = RadbeaconUtils.bytes_to_power(device.values[GATT_POWER])
    self.tx_power = device.values[GATT_TXPOWER]
    self.adv_interval = device.values[GATT_INTERVAL]
  end

  def valid?

  end

  def save!(pin)
    @errors = []
    update_params_commands = ["#{GATT_DEV_NAME} #{RadbeaconUtils.name_to_bytes(self.dev_name)}",
      "#{GATT_UUID} #{RadbeaconUtils.uuid_to_bytes(self.uuid)}", "#{GATT_MAJOR} #{RadbeaconUtils.major_minor_to_bytes(self.major)}",
      "#{GATT_MINOR} #{RadbeaconUtils.major_minor_to_bytes(self.minor)}", "#{GATT_POWER} #{RadbeaconUtils.power_to_bytes(self.power)}", "#{GATT_TXPOWER} 0f",
      "#{GATT_INTERVAL} 8000", "#{GATT_ACTION} #{GATT_ACTION_UPDATE_ADV}", "#{GATT_PIN} #{RadbeaconUtils.pin_to_bytes(pin)}"]
      result = con(update_params_commands)
  end

  def change_pin(new_pin, old_pin)
    @errors = []
    update_pin_commands = ["#{GATT_NEW_PIN} #{RadbeaconUtils.pin_to_bytes(new_pin)}", "#{GATT_ACTION} #{GATT_ACTION_UPDATE_PIN}",
      "#{GATT_PIN} #{RadbeaconUtils.pin_to_bytes(old_pin)}"]
    result = con(update_pin_commands)
  end

  def factory_reset(pin)
    @errors = []
    reset_commands = ["#{GATT_ACTION} #{GATT_ACTION_FACTORY_RESET}", "#{GATT_PIN} #{RadbeaconUtils.pin_to_bytes(pin)}"]
    result = con(reset_commands)
    #self.fetch_params
    result
  end

  def boot_to_dfu(pin)
    @errors = []
    dfu_commands = ["#{GATT_ACTION} #{GATT_ACTION_DFU}", "#{GATT_PIN} #{RadbeaconUtils.pin_to_bytes(pin)}"]
    result = con(dfu_commands)
  end

  def lock(pin)
    @errors = []
    lock_commands = ["#{GATT_ACTION} #{GATT_ACTION_LOCK}", "#{GATT_PIN} #{RadbeaconUtils.pin_to_bytes(pin)}"]
    result = con(lock_commands)
  end

  private

  attr_writer :mac_address, :errors, :dev_model, :dev_id, :dev_version

  def con(commands)
    result = false
    timeout = 0.5
    cmd = "gatttool -b #{self.mac_address} --interactive"
    PTY.spawn(cmd) do |output, input, pid|
      output.expect(/\[LE\]>/)
      input.puts "connect"
      if output.expect(/Connection successful/, timeout)
        commands.each do |cmd|
          cmd = "char-write-req #{cmd}"
          input.puts cmd
          if output.expect(/Characteristic value was written successfully/, timeout)
            result = true
          else
            @errors << "Write parameters failed: #{cmd}"
            result = false
            break
          end
        end
        if result
          input.puts "char-read-hnd #{GATT_RESULT}"
          if output.expect(/Characteristic value\/descriptor: 00 00 00 00/, timeout)
            result = true
          else
            @errors << "Invalid PIN"
            result = false
          end
        end
      else
        @errors << "Connection failed"
      end
      input.puts "quit"
      _, status = Process.waitpid2(pid)
      if !status.success?
        result = false
        @errors << "Process failed to exit properly"
      end
    end
    result
  end

end
