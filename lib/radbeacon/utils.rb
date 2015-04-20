module Radbeacon
  module Utils

    def text_to_bytes(text)
      text.unpack('H*')[0]
    end

    def bytes_to_text(bytes)
      [bytes.delete(' ')].pack('H*').gsub(/\x00/,'')
    end

    def uuid_to_bytes(uuid)
      uuid.gsub(/-/, '')
    end

    def bytes_to_uuid(bytes)
      bytes.delete(' ').sub(/([a-fA-F0-9]{8})([a-fA-F0-9]{4})([a-fA-F0-9]{4})([a-fA-F0-9]{4})([a-fA-F0-9]{12})/, '\1-\2-\3-\4-\5').upcase
    end

    def major_minor_to_bytes(value)
      sprintf("%04x", value.to_i)
    end

    def bytes_to_major_minor(bytes)
      bytes.delete(' ').to_i(16)
    end

    def power_to_bytes(power)
      sprintf("%x", power.to_i + 256)
    end

    def bytes_to_power(bytes)
      bytes.to_i(16) - 256
    end

    def pin_to_bytes(pin)
      pin.unpack('H*')[0]
    end

  end
end
