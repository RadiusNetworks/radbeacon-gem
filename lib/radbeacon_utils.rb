module RadbeaconUtils

  def self.text_to_bytes(text)
    bytes = text.unpack('H*')[0]
  end

  def self.bytes_to_text(bytes)
    text = [bytes.delete(' ')].pack('H*').gsub(/\x00/,'')
  end

  def self.uuid_to_bytes(uuid)
    bytes = uuid.gsub(/-/, '')
  end

  def self.bytes_to_uuid(bytes)
    uuid = bytes.delete(' ').sub(/([a-fA-F0-9]{8})([a-fA-F0-9]{4})([a-fA-F0-9]{4})([a-fA-F0-9]{4})([a-fA-F0-9]{12})/, '\1-\2-\3-\4-\5').upcase
  end

  def self.major_minor_to_bytes(value)
    bytes = sprintf("%04x", value.to_i)
  end

  def self.bytes_to_major_minor(bytes)
    value = bytes.delete(' ').to_i(16)
  end

  def self.power_to_bytes(power)
    bytes = sprintf("%x", power.to_i + 256)
  end

  def self.bytes_to_power(bytes)
    power = bytes.to_i(16) - 256
  end

  def self.pin_to_bytes(pin)
    bytes = pin.unpack('H*')[0]
  end

end
