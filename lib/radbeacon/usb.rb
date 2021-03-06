module Radbeacon
  class Usb < BluetoothLeDevice
    include Utils

    ## Define GATT characteristic constants
    # Generic Access Profile
    C_DEVICE_NAME = "0x0003"
    C_APPEARANCE  = "0x0006"
    # Device Information
    C_MANUFACTURER_NAME = "0x000a"
    C_MODEL_NUMBER      = "0x000d"
    C_SERIAL_STRING     = "0x0010"
    C_FIRMWARE_STRING   = "0x0013"
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
    TRANSMIT_POWER_VALUES = {-23 => "00", -21 => "01", -18 => "03", -14 => "05",
      -11 => "07", -7 => "09", -4 => "0b", 0 => "0d", 3 => "0f"}
    DEFAULT_MEASURED_POWER_VALUES = [-94, -92, -90, -86, -84, -79, -74, -72, -66]
    ADVERTISING_RATE_VALUES = {0 => "0000", 1 => "2006", 2 => "0003", 3 => "f501", 4 => "7001",
      5 => "2001", 6 => "ea00", 7 => "c400", 8 => "a800", 9 => "9100", 10 => "8000"}
    BEACON_TYPES = {"ibeacon" => "01", "altbeacon" => "02", "dual" => "03"}

    ## Timeout length for GATT commands
    TIMEOUT = 0.5

    ## Valid UUID pattern
    VALID_UUID = /^[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}$/

    attr_reader :mac_address, :errors, :dev_model, :dev_id, :dev_version
    attr_accessor :dev_name, :uuid, :major, :minor, :power, :tx_power, :adv_rate, :beacon_type

    def self.create_if_valid(device)
      # Check everything
      required_attrs = [GATT_DEV_MODEL, GATT_DEV_ID, GATT_FWVERSION, GATT_DEV_NAME,
        GATT_UUID, GATT_MAJOR, GATT_MINOR, GATT_POWER, GATT_TXPOWER, GATT_INTERVAL, GATT_BCTYPE]
      if required_attrs.all? { |key| device.values[key] }
        self.new(device)
      end
    end

    def initialize(device)
      @errors = []
      @mac_address = device.mac_address
      @dev_model = bytes_to_text(device.values[GATT_DEV_MODEL])
      @dev_id =  bytes_to_text(device.values[GATT_DEV_ID])
      @dev_version =  bytes_to_text(device.values[GATT_FWVERSION])
      @dev_name =  bytes_to_text(device.values[GATT_DEV_NAME])
      @uuid =  bytes_to_uuid(device.values[GATT_UUID])
      @major =  bytes_to_major_minor(device.values[GATT_MAJOR])
      @minor = bytes_to_major_minor(device.values[GATT_MINOR])
      @power = bytes_to_power(device.values[GATT_POWER])
      @tx_power = TRANSMIT_POWER_VALUES.key(device.values[GATT_TXPOWER])
      @adv_rate = ADVERTISING_RATE_VALUES.key(device.values[GATT_INTERVAL].delete(' '))
      @beacon_type = BEACON_TYPES.key(device.values[GATT_BCTYPE])
    end

    def valid?
      @errors = []
      @errors << "Invalid device name" unless @dev_name.length <= 20
      @errors << "Invalid UUID" unless @uuid.match(VALID_UUID)
      @errors << "Invalid major value" unless @major.to_i.between?(0, 65535)
      @errors << "Invalid minor value" unless @minor.to_i.between?(0, 65535)
      @errors << "Invalid measured power value" unless @power.to_i.between?(-127, -1)
      @errors << "Invalid transmit power" unless TRANSMIT_POWER_VALUES.has_key?(@tx_power)
      @errors << "Invalid advertising rate" unless ADVERTISING_RATE_VALUES.has_key?(@adv_rate)
      @errors << "Invalid beacon type" unless BEACON_TYPES.has_key?(@beacon_type)
      if @errors.empty?
        true
      else
        false
      end
    end

    def save(pin)
      if self.valid?
        update_params_commands = ["#{GATT_DEV_NAME} #{text_to_bytes(@dev_name)}",
          "#{GATT_UUID} #{uuid_to_bytes(@uuid)}", "#{GATT_MAJOR} #{major_minor_to_bytes(@major)}",
          "#{GATT_MINOR} #{major_minor_to_bytes(@minor)}", "#{GATT_POWER} #{power_to_bytes(@power)}",
          "#{GATT_TXPOWER} #{TRANSMIT_POWER_VALUES[@tx_power]}", "#{GATT_INTERVAL} #{ADVERTISING_RATE_VALUES[@adv_rate]}",
          "#{GATT_BCTYPE} #{BEACON_TYPES[@beacon_type]}", "#{GATT_ACTION} #{GATT_ACTION_UPDATE_ADV}", "#{GATT_PIN} #{pin_to_bytes(pin)}"]
        con(update_params_commands)
      else
        false
      end
    end

    def change_pin(new_pin, old_pin)
      update_pin_commands = ["#{GATT_NEW_PIN} #{pin_to_bytes(new_pin)}", "#{GATT_ACTION} #{GATT_ACTION_UPDATE_PIN}",
        "#{GATT_PIN} #{pin_to_bytes(old_pin)}"]
      con(update_pin_commands)
    end

    def factory_reset(pin)
      reset_commands = ["#{GATT_ACTION} #{GATT_ACTION_FACTORY_RESET}", "#{GATT_PIN} #{pin_to_bytes(pin)}"]
      con(reset_commands) && defaults
    end

    def boot_to_dfu(pin)
      dfu_commands = ["#{GATT_ACTION} #{GATT_ACTION_DFU}", "#{GATT_PIN} #{pin_to_bytes(pin)}"]
      con(dfu_commands)
    end

    def lock(pin)
      lock_commands = ["#{GATT_ACTION} #{GATT_ACTION_LOCK}", "#{GATT_PIN} #{pin_to_bytes(pin)}"]
      con(lock_commands)
    end

    protected

    attr_writer :mac_address, :errors, :dev_model, :dev_id, :dev_version

    private

    def defaults
      @dev_name = "RadBeacon USB"
      @uuid = "2F234454-CF6D-4A0F-ADF2-F4911BA9FFA6"
      @major = 1
      @minor = 1
      @power = -66
      @tx_power = 3
      @adv_rate = 10
      @beacon_type = "dual"
    end

    def con(commands)
      @errors = []
      result = false
      cmd_line = "gatttool -b #{@mac_address} --interactive"
      PTY.spawn(cmd_line) do |output, input, pid|
        output.expect(/\[LE\]>/)
        input.puts "connect"
        if output.expect(/Connection successful/, TIMEOUT)
          commands.each do |cmd|
            cmd = "char-write-req #{cmd}"
            input.puts cmd
            if output.expect(/Characteristic value was written successfully/, TIMEOUT)
              result = true
            else
              @errors << "Action failed: #{cmd}"
              result = false
              break
            end
          end
          if result
            input.puts "char-read-hnd #{GATT_RESULT}"
            if output.expect(/Characteristic value\/descriptor: 00 00 00 00/, TIMEOUT)
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
end
