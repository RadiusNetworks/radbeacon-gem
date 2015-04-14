require 'le_scanner'

describe LeScanner do
  describe '#scan' do
    scanner = LeScanner.new(5)
    devices = scanner.scan
    it "scans for beacons" do
      expect(devices.length).to be > 0
    end

    it "filters out duplicate beacons in one scan" do 
      expect(devices.uniq.length).to eq devices.length
    end
  end
end
