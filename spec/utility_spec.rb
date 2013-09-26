require 'spec_helper'

describe Palimpsest::Utility do

  describe ".make_random_directory" do

    root, prefix = '/tmp', 'rspec'

    it "makes a directory where expected" do
      dir = Palimpsest::Utility.make_random_directory root, prefix
      expect(Dir.exists? dir).to be_true
      FileUtils.remove_entry_secure dir if dir =~ %r{^/tmp}
    end
  end

  describe ".validate_path" do

    context "valid path" do

      it "returns the input path" do
        expect(Palimpsest::Utility.validate_path '/path').to eq '/path'
      end

      it "returns the input path when the root path matches" do
        expect(Palimpsest::Utility.validate_path '/path/to/dir', '/path/to').to eq '/path/to/dir'
      end

    end

    context "bad path" do

      it "rasises an error if path contains '../'" do
        expect { Palimpsest::Utility.validate_path 'path/with/../in/it' }.to raise_error RuntimeError
      end

      it "rasises an error if using '~/'" do
        expect { Palimpsest::Utility.validate_path '~/path' }.to raise_error RuntimeError
      end

      it "rasises an error if given root does not match path root" do
        expect { Palimpsest::Utility.validate_path '/other_root/path', '/root/path' }.to raise_error RuntimeError
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
