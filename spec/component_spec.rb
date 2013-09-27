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
      allow(Dir).to receive(:[]).with('src/path/*').and_return( %w(src/path/1 src/path/2) )
      expect(FileUtils).to receive(:mv).with(%w(src/path/1 src/path/2), 'install/path')
      component.install
    end
  end
end
