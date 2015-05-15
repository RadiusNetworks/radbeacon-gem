require 'spec_helper'
require 'radbeacon'

RSpec.describe Radbeacon::Scanner do

  let(:test_device) {double(:bluetooth_le_device).as_null_object}
  let(:test_usb) {double(:usb).as_null_object}

  def mock_scanner
    allow_any_instance_of(Radbeacon::LeScanner).to receive(:scan).and_return([test_device])
    allow(Radbeacon::Usb).to receive(:create_if_valid).and_return(test_usb)
    allow(Radbeacon::BluetoothLeDevice).to receive(:new).and_return(test_device)
    allow(test_device).to receive(:fetch_characteristics).and_return(true)
  end

  describe '#scan' do
    it "returns a radbeacon when given a BluetoothLeDevice object representing a RadBeacon" do
      mock_scanner
      expect(test_device).to receive(:values).at_least(:once).and_return({"0x0003"=>"52 61 64 42 65 61 63 6f 6e 20 55 53 42"})
      scanner = Radbeacon::Scanner.new
      radbeacons = scanner.scan
      expect(radbeacons.count).to eq(1)
    end

    it "returns nil when given a BluetoothLeDevice object that isn't a RadBeacon" do
      mock_scanner
      expect(test_device).to receive(:values).at_least(:once).and_return({"0x0003"=>"de ad be ef"})
      scanner = Radbeacon::Scanner.new
      radbeacons = scanner.scan
      expect(radbeacons.empty?).to eq(true)
    end
  end

  describe '#fetch' do
    it "returns a radbeacon when given a BluetoothLeDevice object representing a RadBeacon" do
      mock_scanner
      expect(test_device).to receive(:values).at_least(:once).and_return({"0x0003"=>"52 61 64 42 65 61 63 6f 6e 20 55 53 42"})
      scanner = Radbeacon::Scanner.new
      radbeacon = scanner.fetch("11:22:33:44:55:66")
      expect(radbeacon.nil?).to eq(false)
    end

    it "returns nil when given a BluetoothLeDevice object that isn't a RadBeacon" do
      mock_scanner
      expect(test_device).to receive(:values).at_least(:once).and_return({"0x0003"=>"de ad be ef"})
      scanner = Radbeacon::Scanner.new
      radbeacon = scanner.fetch("11:22:33:44:55:66")
      expect(radbeacon.nil?).to eq(true)
    end  end
end
