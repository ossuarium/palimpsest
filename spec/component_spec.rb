require 'spec_helper'

describe Palimpsest::Component do

  subject(:component) { Palimpsest::Component.new }

  describe "#install" do

    it "fails if no source path" do
      component.install_path = 'install/path'
      expect { component.install }.to raise_error RuntimeError
    end

    it "fails if no install path" do
      component.source_path = 'src/path'
      expect { component.install }.to raise_error RuntimeError
    end

    it "moves the component to the install path" do
      component.source_path = 'src/path'
      component.install_path = 'install/path'
      expect(FileUtils).to receive(:mkdir_p).with('install/path')
      expect(Palimpsest::Utils).to receive(:copy_directory).with('src/path', 'install/path')
      component.install
    end
  end
end
