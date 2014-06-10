require 'spec_helper'

describe Palimpsest::Utils do

  subject(:object) { Object.new.extend(Palimpsest::Utils) }

  describe "#safe_path?" do

    context "valid path" do

      it "returns true" do
        expect(object.safe_path? 'path').to be true
      end
    end

    context "invalid path" do

      it "returns false if path contains '../'" do
        expect(object.safe_path? 'path/with/../in/it').to be false
      end

      it "returns false if using '~/'" do
        expect(object.safe_path? '~/path').to be false
      end

      it "returns false if path starts with '/'" do
        expect(object.safe_path? '/path').to be false
      end
    end
  end

  describe "#write_to_file" do

    let(:file) { double File }
    let(:mtime) { Time.now }

    before :each do
      allow(File).to receive(:open).with('path/to/file', 'w').and_yield(file)
    end

    it "writes to file" do
      expect(file).to receive(:write).with('data')
      object.write_to_file 'data', 'path/to/file'
    end

    it "can preserve atime and mtime" do
      allow(file).to receive(:write)
      allow(File).to receive(:mtime).with('path/to/file').and_return(mtime)
      expect(File).to receive(:utime).with(mtime, mtime, 'path/to/file')
      object.write_to_file 'data', 'path/to/file', preserve: true
    end
  end

  describe "#copy_directory" do

    before :each do
      stub_const('Palimpsest::Utils::COPY_BACKENDS', [:not_a_backend, :good_backend, :stdlib])
      allow(object).to receive(:backends).and_return([:good_backend, :stdlib])
      Palimpsest::Utils::COPY_BACKENDS.each { |b| allow(object).to receive "copy_directory_with_#{b}".to_sym }
    end

    it "runs the correct directory copy method" do
      expect(object).to receive(:copy_directory_with_stdlib).with('src', 'dest', exclude: ['.git'], mirror: true)
      object.copy_directory 'src', 'dest', backend: :stdlib, exclude: ['.git'], mirror: true
    end

    it "automatically selects first available backend" do
      expect(object).to receive(:copy_directory_with_good_backend)
      object.copy_directory 'src', 'dest'
    end

    it "fails when backend not available" do
      expect { object.copy_directory 'src', 'dest', backend: :not_a_backend }.to raise_error RuntimeError, /backend/
    end
  end

  describe "#search_files" do

    before :each do
      stub_const('Palimpsest::Utils::FILE_SEARCH_BACKENDS', [:not_a_backend, :good_backend, :stdlib])
      allow(object).to receive(:backends).and_return([:good_backend, :stdlib])
      Palimpsest::Utils::FILE_SEARCH_BACKENDS.each { |b| allow(object).to receive "search_files_with_#{b}".to_sym }
    end

    it "runs the correct search method" do
      expect(object).to receive(:search_files_with_stdlib).with(/regex/, 'path')
      object.search_files /regex/, 'path', backend: :stdlib
    end

    it "automatically selects first available backend" do
      expect(object).to receive(:search_files_with_good_backend)
      object.search_files /regex/, 'path'
    end

    it "fails when backend not available" do
      expect { object.search_files /regex/, 'path', backend: :not_a_backend }.to raise_error RuntimeError, /backend/
    end
  end
end
