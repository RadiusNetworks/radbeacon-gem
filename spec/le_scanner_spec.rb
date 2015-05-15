require 'spec_helper'
require 'radbeacon'

RSpec.describe Radbeacon::LeScanner do
  def mock_scanner
    allow_any_instance_of(Radbeacon::LeScanner).to receive(:scan_command).and_return("LE Scan ...\n00:07:80:03:88:99 (unknown)\n00:07:80:15:74:5B (unknown)\n00:07:80:15:74:5B (unknown)")
    allow_any_instance_of(Radbeacon::BluetoothLeDevice).to receive(:fetch_characteristics).and_return(true)
  end

  describe '#scan' do
    it "scans for beacons" do
      mock_scanner
      scanner = Radbeacon::LeScanner.new
      devices = scanner.scan
      expect(devices.length).to be > 0
    end

    it "filters out duplicate beacons in one scan" do
      mock_scanner
      scanner = Radbeacon::LeScanner.new
      devices = scanner.scan
      expect(devices.uniq.length).to eq devices.length
    end
  end
end
