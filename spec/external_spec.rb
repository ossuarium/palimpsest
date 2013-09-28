require 'spec_helper'

describe Palimpsest::External do

  subject(:external) { Palimpsest::External.new source: 'path/to/source', branch: 'my_feature' }

  let(:gritty) { double Grit::Git }
  let(:repo) { double Grit::Repo }

  before :each do
    allow(Grit::Git).to receive(:new).and_return(gritty)
    allow(Grit::Repo).to receive(:new).and_return(repo)
    allow(gritty).to receive(:clone)
  end

  describe "#environment" do

    it "returns a new environment" do
      expect(external.environment).to be_a Palimpsest::Environment
    end

    it "sets the treeish for the environment" do
      expect(external.environment.treeish).to eq 'my_feature'
    end

    it "sets the repo for the environment" do
      expect(external.environment.site.repo).to equal repo
    end
  end

  describe "#tmp_environment" do

    it "fails if no source" do
      external.source = ''
      expect { external.tmp_environment }.to raise_error RuntimeError
    end

    it "returns a new environment" do
      expect(external.tmp_environment).to be_a Palimpsest::Environment
    end

    it "sets the treeish for the environment" do
      expect(gritty).to receive(:clone).with( { branch: 'my_feature' }, external.source, anything )
      external.tmp_environment
    end
  end

  describe "#cleanup" do

    it "cleans environment" do
      expect(external.environment).to receive(:cleanup)
      external.cleanup
    end
    it "clears @environment" do
      expect(external.instance_variable_get :@environment).to be_nil
      external.cleanup
    end

    it "cleans tmp_environment" do
      expect(external.tmp_environment).to receive(:cleanup)
      external.cleanup
    end

    it "clears @tmp_environment" do
      expect(external.instance_variable_get :@tmp_environment).to be_nil
      external.cleanup
    end
  end
end