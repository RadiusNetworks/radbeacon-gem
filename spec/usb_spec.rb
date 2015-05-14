require 'spec_helper'
require 'radbeacon'

RSpec.describe Radbeacon::Usb do

  let(:test_device) {Radbeacon::BluetoothLeDevice.new("11:22:33:44:55:66", "Test Device")}

  VALID_VALUES = {"0x0003"=>"52 61 64 42 65 61 63 6f 6e 20 55 53 42", "0x0006"=>"00 00",
    "0x000a"=>"52 61 64 69 75 73 20 4e 65 74 77 6f 72 6b 73 2c 20 49 6e 63 2e", "0x000d"=>"30 30 30 31", "0x0010"=>"30 30 30 30",
    "0x0013"=>"32 2e 30", "0x0017"=>"52 61 64 42 65 61 63 6f 6e 20 55 53 42 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00",
    "0x001a"=>"30 30 30 37 38 30 31 35 37 34 35 62", "0x001d"=>"5a 42 4f 58 5f 38 36 37 5f 35 33 30 39 00 00 00 00 00 00 00 00 00
    00 00 00 00 00 00 00 00 00 00 00 00 00 00 00", "0x0020"=>"84 2a f9 c4 08 f5 11 e3 92 82 f2 3c 91 ae c0 5e", "0x0023"=>"00 04",
    "0x0026"=>"14 bd", "0x0029"=>"be", "0x002c"=>"0f", "0x002f"=>"80 00", "0x0032"=>"00 00 00 00", "0x003e"=>"03",
    "0x0041"=>"32 2e 32 00 00 00 00", "0x0044"=>"00 00 00 00", "0x0047"=>"00"}
  NIL_VALUES = {"0x0003"=>nil, "0x0006"=>nil, "0x000a"=>nil, "0x000d"=>nil, "0x0010"=>nil,
    "0x0013"=>nil, "0x0017"=>nil, "0x001a"=>nil, "0x001d"=>nil, "0x0020"=>nil, "0x0023"=>nil,
    "0x0026"=>nil, "0x0029"=>nil, "0x002c"=>nil, "0x002f"=>nil, "0x0032"=>nil, "0x003e"=>nil,
    "0x0041"=>nil, "0x0044"=>nil, "0x0047"=>nil}

  describe '#self.create_if_valid' do
    it "creates a radbeacon object given a valid BluetoothLeDevice" do
      expect(test_device).to receive(:values).at_least(:once).and_return(VALID_VALUES)
      radbeacon = Radbeacon::Usb.create_if_valid(test_device)
      expect(radbeacon.class).to eq(Radbeacon::Usb)
    end

    it "returns nil given an invalid BluetoothLeDevice" do
      expect(test_device).to receive(:values).at_least(:once).and_return(NIL_VALUES)
      radbeacon = Radbeacon::Usb.create_if_valid(test_device)
      expect(radbeacon).to eq(nil)
    end
  end
end
