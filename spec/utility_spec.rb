require 'spec_helper'

describe Palimpsest::Utility do

  describe ".make_random_directory" do

    root, prefix = '/tmp', 'rspec'

    it "makes a directory where expected" do
      dir = Palimpsest::Utility.make_random_directory root, prefix
      expect(Dir.exists? dir).to be true
      FileUtils.remove_entry_secure dir if dir =~ %r{^/tmp}
    end
  end

  describe ".safe_path?" do

    context "valid path" do

      it "returns true" do
        expect(Palimpsest::Utility.safe_path? 'path').to be true
      end
    end

    context "invalid path" do

      it "returns false if path contains '../'" do
        expect(Palimpsest::Utility.safe_path? 'path/with/../in/it').to be false
      end

      it "returns false if using '~/'" do
        expect( Palimpsest::Utility.safe_path? '~/path').to be false
      end

      it "returns false if path starts with '/'" do
        expect(Palimpsest::Utility.safe_path? '/path').to be false
      end
    end
  end

  describe "write" do

    let(:file) { double File }
    let(:mtime) { Time.now }

    before :each do
      allow(File).to receive(:open).with('path/to/file', 'w').and_yield(file)
    end

    it "writes to file" do
      expect(file).to receive(:write).with('data')
      Palimpsest::Utility.write 'data', 'path/to/file'
    end

    it "can preserve atime and mtime" do
      allow(file).to receive(:write)
      allow(File).to receive(:mtime).with('path/to/file').and_return(mtime)
      expect(File).to receive(:utime).with(mtime, mtime, 'path/to/file')
      Palimpsest::Utility.write 'data', 'path/to/file', preserve: true
    end
  end
end
