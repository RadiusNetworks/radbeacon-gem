module Radbeacon
  module Utils

    def text_to_bytes(text)
      text.unpack('H*')[0] if text
    end

    def bytes_to_text(bytes)
      [bytes.delete(' ')].pack('H*').gsub(/\x00/,'') if bytes
    end

    def uuid_to_bytes(uuid)
      uuid.gsub(/-/, '') if uuid
    end

    def bytes_to_uuid(bytes)
      bytes.delete(' ').sub(/([a-fA-F0-9]{8})([a-fA-F0-9]{4})([a-fA-F0-9]{4})([a-fA-F0-9]{4})([a-fA-F0-9]{12})/, '\1-\2-\3-\4-\5').upcase if bytes
    end

    def major_minor_to_bytes(value)
      sprintf("%04x", value.to_i) if value
    end

    def bytes_to_major_minor(bytes)
      bytes.delete(' ').to_i(16) if bytes
    end

    def power_to_bytes(power)
      sprintf("%x", power.to_i + 256) if power
    end

    def bytes_to_power(bytes)
      bytes.to_i(16) - 256 if bytes
    end

    def pin_to_bytes(pin)
      pin.unpack('H*')[0] if pin
    end

  end
end
