require 'spec_helper'

describe Palimpsest::External do

  subject(:external) { Palimpsest::External.new }

  describe "#repository_path" do

    context "when local repository" do

      before :each do
        external.name = 'my_app'
        external.source = 'path/to/source'
      end

      it "gives the full path" do
        expect(Dir).to receive(:exist?).with('path/to/source/my_app').and_return(true)
        expect(external.repository_path).to eq 'path/to/source/my_app'
      end
    end

    context "when remote repository" do

      before :each do
        external.name = 'my_app'
        external.source = 'https://github.com/razor-x'
      end

      it "gives the full url" do
        expect(Dir).to receive(:exist?).with('https://github.com/razor-x/my_app').and_return(false)
        expect(external.repository_path).to eq 'https://github.com/razor-x/my_app'
      end
    end
  end

  describe "#repo" do

    before :each do
      external.name = 'my_app'
    end

    it "is a repo object" do
      expect(external.repo).to be_a Palimpsest::Repo
    end

    it "sets the repository source" do
      external.source = 'repo/src'
      expect(external.repo.source).to eq 'repo/src/my_app'
    end

    it "sets the cache" do
      external.cache = '/tmp/cache'
      expect(external.repo.cache).to eq '/tmp/cache'
    end
  end

  describe "#install" do

    context "when no install path specified" do

      it "fails" do
        expect { external.install }.to raise_error RuntimeError
      end
    end

    it "installs the files to the install path and returns itself" do
      external.install_path = 'path/to/install'
      external.reference = 'v1.0.0'
      expect(FileUtils).to receive(:mkdir_p).with('path/to/install')
      expect(external.repo).to receive(:extract).with(
        'path/to/install', reference: 'v1.0.0'
      )
      expect(external.install).to be external
    end
  end
end
