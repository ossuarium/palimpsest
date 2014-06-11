require 'spec_helper'

describe Palimpsest::Environment do

  let(:site_1) { Palimpsest::Site.new name: 'site_1' }
  let(:site_2) { Palimpsest::Site.new name: 'site_2' }

  subject(:environment) { Palimpsest::Environment.new }

  before :each do
    allow(Kernel).to receive(:system)
  end

  describe ".new" do

    it "sets default options" do
      expect(environment.options).to eq Palimpsest::Environment::DEFAULT_OPTIONS
    end

    it "merges default options" do
      environment = Palimpsest::Environment.new options: { tmp_dir: '/tmp/path' }
      expect(environment.options).to eq Palimpsest::Environment::DEFAULT_OPTIONS.merge(tmp_dir: '/tmp/path')
    end
  end

  describe "#options" do

    it "merges with default options" do
      environment.options[:tmp_dir] = '/tmp/path'
      expect(environment.options).to eq Palimpsest::Environment::DEFAULT_OPTIONS.merge(tmp_dir: '/tmp/path')
    end

    it "can be called twice and merge options" do
      environment.options[:tmp_dir] = '/tmp/path'
      environment.options[:dir_prefix] = '/tmp/path'
      expect(environment.options).to eq Palimpsest::Environment::DEFAULT_OPTIONS.merge(tmp_dir: '/tmp/path', dir_prefix: '/tmp/path')
    end
  end

  describe "#site" do

    it "cannot be redefinfed while populated" do
      environment.site = site_1
      allow(environment).to receive(:populated).and_return(true)
      expect { environment.site = site_2 }.to raise_error RuntimeError, /populated/
    end
  end

  describe "#reference" do

    it "must be a string" do
      expect { environment.reference = 1 }.to raise_error TypeError
    end

    it "cannot be redefinfed while populated" do
      environment.reference = 'reference_1'
      allow(environment).to receive(:populated).and_return(true)
      expect { environment.reference = 'reference_2' }.to raise_error RuntimeError, /populated/
    end
  end

  describe "#repo" do

    before :each do
      site_1.repository = 'repo/src'
    end

    it "is a repo object" do
      expect(environment.repo).to be_a Palimpsest::Repo
    end

    it "sets the repository source" do
      environment.site = site_1
      expect(environment.repo.source).to eq 'repo/src'
    end

     it "sets the cache" do
      environment.options repo_cache_root: '/tmp/cache'
      expect(environment.repo.cache).to eq '/tmp/cache'
    end
  end

  describe "#directory" do

    before :each do
      allow(Dir).to receive(:mktmpdir).and_return('/tmp/rand_dir')
    end

    context "when directory is unset" do

      it "makes and returns a temporary directory" do
        environment.site = site_1
        rest = environment.options[:tmp_dir]
        prefix = "#{environment.options[:dir_prefix]}site_1_"
        expect(Dir).to receive(:mktmpdir).with(prefix, rest).and_return('/tmp/rand_dir')
        expect(environment.directory).to eq '/tmp/rand_dir'
      end
    end

    context "when directory is set" do

      it "returns the current directory" do
        expect(Dir).to receive(:mktmpdir).once
        environment.directory
        expect(environment.directory).to eq '/tmp/rand_dir'
      end
    end
  end

  describe "#copy" do

    it "copies the environment to the destination" do
      dir = environment.directory
      expect(environment).to receive(:copy_directory).with(
        dir, '/dest/path', exclude: environment.options[:copy_exclude], mirror: false
      )
      environment.copy destination: '/dest/path', mirror: false
    end

    context "when destination is nil" do

      it "fails" do
        expect { environment.copy destination: nil }.to raise_error RuntimeError, /destination/
      end
    end
  end

  describe "#cleanup" do

    subject(:environment) { Palimpsest::Environment.new site: site_1 }

    it "removes the directory and resets @directory" do
      expect(FileUtils).to receive(:remove_entry_secure).with(environment.directory)
      environment.directory
      environment.cleanup
      expect(environment.instance_variable_get :@directory).to eq nil
    end

    it "returns itself" do
      expect(environment.cleanup).to be environment
    end
  end

  describe "#populate" do

    it "fails when missing site" do
      environment.reference = 'master'
      expect { environment.populate }.to raise_error RuntimeError, /populate without/
    end

    context "from repository" do

      subject(:environment) { Palimpsest::Environment.new site: site_1, reference: 'master' }

      before :each do
        site_1.repository = 'repo/src'
        allow(environment.repo).to receive(:extract)
      end

      it "extracts the repository to the directory and sets populated true" do
        expect(environment.repo).to receive(:extract).with(
          environment.directory, reference: environment.reference
        )
        environment.populate from: :repository
        expect(environment.populated).to eq true
      end

      it "fails when missing reference" do
        environment.site = site_1
        environment.reference = ''
        expect { environment.populate from: :repository }.to raise_error RuntimeError, /populate without/
      end

      it "returns itself" do
        expect(environment.populate from: :repository).to be environment
      end

      it "will cleanup if populated" do
        environment.populate
        expect(environment).to receive :cleanup
        environment.populate from: :repository
      end
    end

    context "from source" do

      it "copies the source files to the directory preserving mtime" do
        environment.site = site_1
        site_1.source = '/path/to/source'
        expect(environment).to receive(:copy_directory).with(
          '/path/to/source', environment.directory, exclude: environment.options[:copy_exclude]
        )
        environment.populate from: :source
      end

      context "site source not given" do

        it "copies from the working directory" do
          environment.site = site_1
          expect(environment).to receive(:copy_directory).with(
            '.', environment.directory, exclude: environment.options[:copy_exclude]
          )
          environment.populate from: :source
        end
      end
    end
  end

  describe "#config" do

    subject(:environment) { Palimpsest::Environment.new site: site_1, reference: 'master' }

    before :each do
      allow(File).to receive(:exists?).and_return(true)
      allow(YAML).to receive(:load_file).and_return({})
    end

    it "populate if not populated" do
      expect(environment).to receive :populate
      environment.config
    end

    it "populate only if not populated" do
      allow(environment).to receive(:populated).and_return(true)
      expect(environment).not_to receive :populate
      environment.config
    end

    it "loads the config if populated" do
      allow(environment).to receive(:populated).and_return(true)
      expect(YAML).to receive(:load_file).with("#{environment.directory}/palimpsest.yml")
      environment.config
    end

    context "settings given" do

      before :each do
        allow(YAML).to receive(:load_file).with("#{environment.directory}/palimpsest.yml")
        .and_return( { conf_1: :val_1, conf_2: :val_2 } )
      end

      it "merges new settings on first call" do
        expect( environment.config({ conf_3: :val_3 }) ).to eq({ conf_1: :val_1, conf_2: :val_2, conf_3: :val_3 })
      end

      it "merges new settings on subsequent call" do
        environment.config
        expect( environment.config({ conf_3: :val_3 }) ).to eq({ conf_1: :val_1, conf_2: :val_2, conf_3: :val_3 })
      end

      it "remembers new settings" do
        environment.config({ conf_3: :val_3 })
        expect(environment.config).to eq({ conf_1: :val_1, conf_2: :val_2, conf_3: :val_3 })
      end

      it "overwrites current settings" do
        expect( environment.config({ conf_2: :new_val_2 }) ).to eq({ conf_1: :val_1, conf_2: :new_val_2 })
      end
    end
  end

  describe "compile" do

    it "runs all compile tasks and returns self" do
      expect(environment).to receive(:install_externals)
      expect(environment).to receive(:install_components)
      expect(environment).to receive(:compile_assets)
      expect(environment).to receive(:remove_excludes)
      expect(environment.compile).to be environment
    end
  end

  describe "methods that modify the working directory" do

    let(:config) do
      YAML.load <<-EOF
        :components:
          :base: _components
          :paths:
            - [ my_app/templates, apps/my_app/templates ]
            - [ my_app/extra, apps/my_app ]
        :externals:
          :server: "https://github.com/razor-x"
          :repositories:
            - [ my_app, apps/my_app ]
            - [ sub_app, apps/my_app/sub_app, my_feature, "https://bitbucket.org/razorx" ]
        :excludes:
          - .gitignore
          - apps/*/assets
        :assets:
          :options:
            :output: compiled
            :src_pre: "(%"
          :sources:
            - public
            - app/src
          :javascripts:
            :options:
              :js_compressor: :uglifier
              :gzip: true
            :paths:
              - assets/javascripts
              - other/javascripts
          :stylesheets:
            :options:
              :output: css
              :css_compressor: :sass
            :paths:
              - assets/stylesheets
      EOF
    end

    before :each do
      environment.site = site_1
      environment.directory
      allow(environment).to receive(:populated).and_return(true)
      allow(environment).to receive(:config).and_return(config)
    end

    describe "#components" do

      it "returns an array" do
        expect(environment.components).to be_a Array
      end

      it "contains components" do
        expect(environment.components[0]).to be_a Palimpsest::Component
        expect(environment.components[1]).to be_a Palimpsest::Component
      end

      it "sets the components source and install paths" do
        expect(environment.components[0].source_path).to eq "#{environment.directory}/_components/my_app/templates"
        expect(environment.components[0].install_path).to eq "#{environment.directory}/apps/my_app/templates"
      end

      context "when no components given" do

        it "contains no components" do
          allow(environment).to receive(:config).and_return({})
          expect(environment.components).to eq []
        end
      end
    end

    describe "#install_components" do

      it "installs the components and returns itself" do
        expect(environment.components[0]).to receive(:install)
        expect(environment.components[1]).to receive(:install)
        expect(environment.install_components).to be environment
      end

      context "when no components given" do

        it "does nothing and returns itself" do
          allow(environment).to receive(:config).and_return({})
          expect(environment.install_components).to be environment
        end
      end
    end

    describe "#externals" do

      it "returns an array" do
        expect(environment.externals).to be_a Array
      end

      it "contains externals" do
        expect(environment.externals[0]).to be_a Palimpsest::External
        expect(environment.externals[1]).to be_a Palimpsest::External
      end

      it "sets the externals repo path" do
        expect(environment.externals[0].repository_path).to eq 'https://github.com/razor-x/my_app'
        expect(environment.externals[1].repository_path).to eq 'https://bitbucket.org/razorx/sub_app'
      end

      it "sets the externals reference" do
        expect(environment.externals[0].reference).to eq 'master'
        expect(environment.externals[1].reference).to eq 'my_feature'
      end

      it "sets the install path" do
        expect(environment.externals[0].install_path).to eq "#{environment.directory}/apps/my_app"
        expect(environment.externals[1].install_path).to eq "#{environment.directory}/apps/my_app/sub_app"
      end

      context "when no externals given" do

        it "contains no externals" do
          allow(environment).to receive(:config).and_return({})
          expect(environment.externals).to eq []
        end
      end
    end

    describe "#install_externals" do

      context "when externals given" do

        let(:external_1) { double Palimpsest::External }
        let(:external_2) { double Palimpsest::External }

        before :each do
          allow(environment).to receive(:externals).and_return([external_1, external_2])
          allow(external_1).to receive(:install)
          allow(external_2).to receive(:install)
        end

        it "installs the externals and returns itself" do
          expect(external_1).to receive(:install).and_return(external_1)
          expect(external_2).to receive(:install).and_return(external_2)
          expect(environment.install_externals).to be environment
        end
      end

      context "when no externals given" do

        it "does nothing and returns itself" do
          allow(environment).to receive(:config).and_return({})
          expect(environment.install_externals).to be environment
        end
      end
    end

    describe "#remove_excludes" do

      it "removes excluded files and returns itself" do
        allow(Dir).to receive(:[]).with("#{environment.directory}/.gitignore")
        .and_return(["#{environment.directory}/.gitignore"])

        allow(Dir).to receive(:[]).with("#{environment.directory}/apps/*/assets")
        .and_return( %W(#{environment.directory}/apps/app_1/assets #{environment.directory}/apps/app_2/assets) )

        expect(FileUtils).to receive(:remove_entry_secure).with("#{environment.directory}/.gitignore")
        expect(FileUtils).to receive(:remove_entry_secure).with("#{environment.directory}/apps/app_1/assets")
        expect(FileUtils).to receive(:remove_entry_secure).with("#{environment.directory}/apps/app_2/assets")
        expect(environment.remove_excludes).to be environment
      end

      context "when no excludes given" do

        it "does nothing and returns itself" do
          allow(environment).to receive(:config).and_return({})
          expect(environment.remove_excludes).to be environment
        end
      end
    end

    describe "#assets" do

      subject(:assets) { environment.assets }

      it "returns an array" do
        expect(assets).to be_a Array
      end

      it "returns an array of asset objects" do
        expect(assets[0]).to be_a Palimpsest::Assets
        expect(assets[1]).to be_a Palimpsest::Assets
      end

      it "sets the directory for each asset" do
        expect(assets[0].directory).to eq environment.directory
        expect(assets[1].directory).to eq environment.directory
      end

      it "sets the options for each asset" do
        expect(assets[0].options).to include output: 'compiled'
        expect(assets[0].options).to include js_compressor: :uglifier
        expect(assets[0].options).to include gzip: true
        expect(assets[1].options).to include output: 'css'
        expect(assets[1].options).to include css_compressor: :sass
      end

      it "sets the paths for each asset" do
        expect(assets[0].paths).to include 'assets/javascripts'
        expect(assets[0].paths).to include 'other/javascripts'
        expect(assets[1].paths).to include 'assets/stylesheets'
      end

      it "only loads the paths for each type of asset" do
        expect(assets[0].paths).to_not include 'assets/stylesheets'
        expect(assets[1].paths).to_not include 'assets/javascripts'
      end

      context "when no assets given" do

        it "contains no assets" do
          allow(environment).to receive(:config).and_return({})
          expect(assets).to eq []
        end
      end
    end

    describe "#sources_with_assets" do

      let(:dir) { environment.directory }

      it "looks for all asset types" do
        expect(Palimpsest::Assets).to receive(:find_tags).twice.with(anything, nil, anything)
        environment.sources_with_assets
      end

      it "uses options as options" do
        options = { src_pre: '(%', search_backend: environment.options[:search_backend] }
        expect(Palimpsest::Assets).to receive(:find_tags).twice.with(anything, anything, options)
        environment.sources_with_assets
      end

      it "returns assets with tags" do
        allow(Palimpsest::Assets).to receive(:find_tags).with(dir + '/public', anything, anything).and_return(dir + '/public/header.html')
        allow(Palimpsest::Assets).to receive(:find_tags).with(dir + '/app/src', anything, anything).and_return(dir + '/app/src/head.tpl')
        expect(environment.sources_with_assets).to eq [ "#{dir}/public/header.html", "#{dir}/app/src/head.tpl" ]
      end

      context "when no assets given" do

        it "contains no sources with assets" do
          allow(environment).to receive(:config).and_return({})
          expect(environment.sources_with_assets).to eq []
        end
      end
    end

    describe "#compile_assets" do

      let(:sources) { [ "#{environment.directory}/public/header.html", "#{environment.directory}/app/src/head.tpl" ] }

      it "returns itself" do
        allow(environment).to receive(:sources_with_assets).and_return([])
        expect(environment.compile_assets).to be environment
      end

      it "compiles the assets and writes the sources while preserving mtime" do
        allow(environment).to receive(:sources_with_assets).and_return sources
        allow(File).to receive(:read).with(sources[0]).and_return('data_1')
        allow(File).to receive(:read).with(sources[1]).and_return('data_2')
        expect(environment).to receive(:write_to_file).with 'data_1', sources[0], preserve: true
        expect(environment).to receive(:write_to_file).with 'data_2', sources[1], preserve: true
        environment.compile_assets
      end

      context "when no assets given" do

        it "does nothing and returns itself" do
          allow(environment).to receive(:config).and_return({})
          expect(environment.compile_assets).to be environment
        end
      end
    end
  end
end
