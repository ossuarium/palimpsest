require 'spec_helper'

describe Palimpsest::Repo do

  subject(:repo) { Palimpsest::Repo.new }

  describe "#local_clone" do

    it "uses a unique path" do
      repo.cache = '/tmp'
      repo.source = 'src/path'
      expect(repo.local_clone).to eq '/tmp/repo_src_path_b6a728b1177'
    end

    it "cleans the https protocol off the path" do
      repo.cache = '/tmp'
      repo.source = 'https://github.com/razor-x/palimpsest.git'
      expect(repo.local_clone).to eq '/tmp/repo_https___github.com_razor-x_palimpsest.git_02809b17c50'
    end

    it "cleans the git protocol off the path" do
      repo.cache = '/tmp'
      repo.source = 'git@github.com:razor-x/palimpsest.git'
      expect(repo.local_clone).to eq '/tmp/repo_git@github.com_razor-x_palimpsest.git_b9e1373c404'
    end

    context "when source not given" do

      it "returns nil" do
        repo.source = nil
        repo.cache = '/tmp'
        expect(repo.local_clone).to be_nil
      end
    end

    context "when cache not given" do

      it "returns nil" do
        repo.source = 'src/path'
        repo.cache = nil
        expect(repo.local_clone).to be_nil
      end
    end
  end

  describe "#mirror" do

    before :each do
      allow(repo).to receive(:mirror_repo)
    end

    it "mirrors the repo to cache directory" do
      repo.source = 'src/path'
      expect(repo).to receive(:mirror_repo).with('src/path', repo.local_clone)
      repo.mirror
    end

    it "returns mirror location" do
      repo.source = 'src/path'
      repo.local_clone = '/tmp/dest'
      expect(repo.mirror).to eq '/tmp/dest'
    end

    context "when clone directory exists" do

      it "returns the directory" do
        repo.source = 'src/path'
        repo.local_clone = '/tmp/dest'
        allow(Dir).to receive(:exists?).with('/tmp/dest').and_return(true)
        expect(repo.mirror).to eq '/tmp/dest'
      end
    end

    context "when source not given" do

      it "fails" do
        repo.source = nil
        expect { repo.mirror }.to raise_error RuntimeError
      end
    end
   end

  describe "#update" do

    before :each do
      allow(repo).to receive(:mirror)
      allow(repo).to receive(:update_repo)
    end

    it "mirrors the repo" do
      expect(repo).to receive(:mirror)
      repo.update
    end

    it "update the repo" do
      expect(repo).to receive(:update_repo).with(repo.local_clone)
      repo.update
    end
  end

  describe "#extract" do

    before :each do
      allow(repo).to receive(:mirror)
      allow(repo).to receive(:update)
      allow(repo).to receive(:extract_repo)
    end

    it "updates the repo" do
      expect(repo).to receive(:update)
      repo.extract 'dest/path'
    end

    it "extracts the repo" do
      expect(repo).to receive(:extract_repo).with('dest/path', 'my_feature')
      repo.extract 'dest/path', reference: 'my_feature'
    end
  end
end
