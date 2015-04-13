require 'le_scanner'

describe LeScanner do
  describe '#scan' do
    it "scans for beacons"
      scanner = LeScanner.new(5)
      devices = scanner.scan
      expect(devices.length).to be > 0
    end

    it "filters out duplicate beacons in one scan"
      expect(devices.uniq.length).to eq devices.length
    end
  end
end
