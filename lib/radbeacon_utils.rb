module RadbeaconUtils

  def self.text_to_bytes(text)
    bytes = text.unpack('H*')[0]
  end

  def self.bytes_to_text(bytes)
    text = [bytes.delete(' ')].pack('H*').gsub(/\x00/,'')
  end

  def self.uuid_to_bytes(uuid)
    if uuid.match(/^[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}$/)
      bytes = uuid.gsub(/-/, '')
    else
      bytes = nil
    end
    bytes
  end

  def self.bytes_to_uuid(bytes)
    uuid = bytes.delete(' ').sub(/([a-fA-F0-9]{8})([a-fA-F0-9]{4})([a-fA-F0-9]{4})([a-fA-F0-9]{4})([a-fA-F0-9]{12})/, '\1-\2-\3-\4-\5').upcase
  end

  def self.major_minor_to_bytes(value)
    if value.to_i.between?(0, 65535)
      bytes = sprintf("%04x", value.to_i)
    else
      bytes = nil
    end
    bytes
  end

  def self.bytes_to_major_minor(bytes)
    value = bytes.delete(' ').to_i(16)
  end

  def self.power_to_bytes(power)
    if power.to_i.between?(-127, -1)
      bytes = sprintf("%x", power.to_i + 256)
    else
      bytes = nil
    end
    bytes
  end

  def self.bytes_to_power(bytes)
    power = bytes.to_i(16) - 256
  end

  def self.pin_to_bytes(pin)
    if pin.match(/^[0-9]{4}$/)
      bytes = pin.unpack('H*')[0]
    else
      # Invalid PIN
      bytes = nil
    end
    bytes
  end

end
