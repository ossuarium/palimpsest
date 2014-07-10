require 'active_support/core_ext/hash'
require 'tmpdir'

module Palimpsest
  # An environment is populated with the contents of
  # a site's repository at a specified commit.
  # Alternatively, a single directory can be used to populate the environment.
  # The environment's files are rooted in a temporary {#directory}.
  # An environment is the primary way to interact with a site's files.
  #
  # An environment loads a {#config} file from the working {#directory};
  # by default, `palimpsest.yml`.
  #
  # Paths are all relative to the working {#directory}.
  #
  # ````yml
  # # example of palimpsest.yml
  #
  # # persistent files and directories
  # persistent:
  #   - config.php
  #   - data/
  #
  # # component settings
  # components:
  #   # all component paths are relative to the base
  #   base: _components
  #
  #   # list of components
  #   paths:
  #    #- [ components_path, install_path ]
  #     - [ my_app/templates, apps/my_app/templates ]
  #     - [ my_app/extra, apps/my_app ]
  #
  # # externals settings
  # externals:
  #   # server or local path that repositories are under
  #   server: "https://github.com/razor-x"
  #
  #   # list of external repositories
  #   repositories:
  #       # uses repository at https://github.com/razor-x/my_app
  #       # and installs to apps/my_app
  #     - name: my_app
  #       path: apps/my_app
  #
  #       # uses repository at https://bitbucket.org/razorx/sub_app
  #       # and installs to apps/my_app from git reference v1.0.0
  #     - name: sub_app
  #       path: apps/my_app/sub_app
  #       reference: v1.0.0
  #       server: apps/my_app
  #
  # # list of excludes
  # # matching paths are removed with {#remove_excludes}.
  # excludes:
  #   - _assets
  #   - apps/*/.gitignore
  #
  # # asset settings
  # assets:
  #   # all options are passed to Assets#options
  #   # options will use defaults set in Palimpsest::Asset::DEFAULT_OPTIONS if unset here
  #   # unless otherwise mentioned, options can be set or overridden per asset type
  #   options:
  #     # opening and closing brackets for asset source tags
  #     # global option only: cannot be overridden per asset type
  #     src_pre: "[%"
  #     src_post: "%]"
  #
  #     # relative directory to save compiled assets
  #     output: compiled
  #
  #     # assume assets will be served under here
  #     cdn: https://cdn.example.com/
  #
  #     # compiled asset names include a uniqe hash by default
  #     # this can be toggled off
  #     hash: false
  #
  #   # directories to scan for files with asset tags
  #   sources:
  #     # putting assets/stylesheets first would allow asset tags,
  #     # e.g. for images, to be used in your stylesheets
  #     - assets/stylesheets
  #     - public
  #     - app/src
  #
  #   # all other keys are asset types
  #   javascripts:
  #     options:
  #       js_compressor: :uglifier
  #     # these paths are loaded into the sprockets environment
  #     paths:
  #       - assets/javascripts
  #       - other/javascripts
  #
  #   # this is another asset type which will have it's own namespace
  #   stylesheets:
  #     options:
  #       css_compressor: :sass
  #
  #     paths:
  #       - assets/stylesheets
  #   # images can be part of the asset pipeline
  #   images:
  #     options:
  #       # requires the sprockets-image_compressor gem
  #       image_compression: true
  #       # options can be overridden per type
  #       output: images
  #     paths:
  #       - assets/images
  # ````
  class Environment
    # Default {#options}.
    DEFAULT_OPTIONS = {
      # Backend to use for file search operations.
      # :grep to use grep.
      search_backend: :grep,

      # Backend to use for multi-file copy operations.
      # :rsync to use rsync.
      copy_backend: :rsync,

      # Files and directories that should never
      # be copied to the working environment.
      copy_exclude: %w(.git .svn),

      # Directory to store cached repository clones.
      repo_cache_root: Palimpsest::Repo::CACHE,

      # All environment's temporary directories will be rooted under here.
      tmp_dir: Dir.tmpdir,

      # Prepended to the name of the environment's working directory.
      dir_prefix: 'palimpsest_',

      # Name of config file to load, relative to environment's working directory.
      config_file: 'palimpsest.yml'
    }

    # @!attribute site
    #   @return site to build the environment with
    #
    # @!attribute reference
    #   @return [String] the reference used to pick the commit to build the environment with
    #
    # @!attribute [r] populated
    #   @return [Boolean] true if the site's repository has been extracted
    attr_reader :site, :reference, :populated

    def initialize(site: nil, reference: 'master', options: {})
      @populated = false
      self.options options
      self.site = site if site
      self.reference = reference
    end

    # Uses {DEFAULT_OPTIONS} as initial value.
    # @param options [Hash] merged with current options
    # @return [Hash] current options
    def options(options = {})
      @options ||= DEFAULT_OPTIONS
      @options = @options.merge options
    end

    # @see Environment#site
    def site=(site)
      fail "Cannot redefine 'site' once populated" if populated
      @site = site
    end

    # @see Environment#reference
    def reference=(reference)
      fail "Cannot redefine 'reference' once populated" if populated
      fail TypeError unless reference.is_a? String
      @reference = reference
    end

    # The corresponding {Repo} for this environment.
    def repo
      @repo = nil if site.repository != @repo.source unless @repo.nil?
      @repo = nil if options[:repo_cache_root] != @repo.cache unless @repo.nil?
      @repo ||= Repo.new.tap do |r|
        r.cache = options[:repo_cache_root]
        r.source = site.repository unless site.nil?
      end
    end

    # @return [String] the environment's working directory
    def directory
      @directory ||= Dir.mktmpdir(
        "#{options[:dir_prefix]}#{site.nil? ? '' : site.name}_",
        options[:tmp_dir]
      )
    end

    # Copy the contents of the working directory.
    # @param destination [String] path to copy environment's files to
    # @param mirror [Boolean] remove any non-excluded paths from destination
    # @return [Environment] the current environment instance
    def copy(destination: site.path, mirror: false)
      fail 'Must specify a destination' if destination.nil?
      exclude = options[:copy_exclude]
      exclude.concat config[:persistent] unless config[:persistent].nil?
      Utils.copy_directory directory, destination, exclude: exclude, mirror: mirror
      self
    end

    # Removes the environment's working directory.
    # @return [Environment] the current environment instance
    def cleanup
      FileUtils.remove_entry_secure directory if @directory
      @config = nil
      @directory = nil
      @assets = []
      @components = []
      @populated = false
      self
    end

    # Extracts the site's files from repository to the working directory.
    # @return [Environment] the current environment instance
    def populate(from: :auto)
      return if populated
      fail "Cannot populate without 'site'" if site.nil?

      case from
      when :auto
        if site.respond_to?(:repository) ? site.repository : nil
          populate from: :repository
        else
          populate from: :source
        end
      when :repository
        fail "Cannot populate without 'reference'" if reference.empty?
        repo.extract directory, reference: reference
        @populated = true
      when :source
        source = site.source.nil? ? '.' : site.source
        Utils.copy_directory source, directory, exclude: options[:copy_exclude]
        @populated = true
      end

      self
    end

    # @param settings [Hash] merged with current config
    # @return [Hash] configuration loaded from {#options}`[:config_file]` under {#directory}
    def config(settings = {})
      settings = ActiveSupport::HashWithIndifferentAccess.new settings

      if @config.nil?
        populate unless populated
        file = File.join(directory, options[:config_file])
        @config = YAML.load_file(file) if File.exist? file
        @config = ActiveSupport::HashWithIndifferentAccess.new @config
        validate_config if @config
      end

      @config.nil? ? settings : @config.deep_merge!(settings)
    end

    # Runs all compile tasks.
    # @return [Environment] the current environment instance
    def compile
      populate
      install_externals
      install_components
      compile_assets
      remove_excludes
      self
    end

    # @return [Array<Component>] components with paths loaded from config
    def components
      return @components if @components
      return [] if config[:components].nil?
      return [] if config[:components][:paths].nil?

      @components = []

      base = directory
      base = File.join directory, config[:components][:base] unless config[:components][:base].nil?

      config[:components][:paths].each do |paths|
        @components << Component.new.tap do |c|
          c.source_path = File.join(base, paths[0])
          c.install_path = File.join(directory, paths[1])
        end
      end

      @components
    end

    # Install all components.
    # @return [Environment] the current environment instance
    def install_components
      components.each { |c| c.install }
      self
    end

    # @return [Array<External>] externals loaded from config
    def externals
      return @externals if @externals
      return [] if config[:externals].nil?
      return [] if config[:externals][:repositories].nil?

      @externals = []

      config[:externals][:repositories].each do |repo|
        @externals << External.new.tap do |e|
          e.name = repo[:name]
          e.source = repo[:server].nil? ? config[:externals][:server] : repo[:server]
          e.reference = repo[:reference] unless repo[:reference].nil?
          e.install_path = File.join directory, repo[:path]
        end
      end

      @externals
    end

    # Install all externals.
    # @return [Environment] the current environment instance
    def install_externals
      externals.each { |e| e.install }
      self
    end

    # Remove all excludes defined by `config[:excludes]`.
    # @return [Environment] the current environment instance
    def remove_excludes
      return self if config[:excludes].nil?
      config[:excludes].map { |e| Dir["#{directory}/#{e}"] }.flatten.each do |e|
        FileUtils.remove_entry_secure e
      end
      self
    end

    # @return [Array<Assets>] assets with settings and paths loaded from config
    def assets
      return @assets if @assets

      @assets = []

      config[:assets].each do |type, opt|
        next if [:sources].include? type.to_sym
        next if opt[:paths].nil?

        @assets << Assets.new.tap do |a|
          a.type = type
          a.directory = directory
          a.paths = opt[:paths]
          a.options config[:assets][:options].symbolize_keys unless config[:assets][:options].nil?
          a.options opt[:options].symbolize_keys unless opt[:options].nil?
        end
      end unless config[:assets].nil?

      @assets
    end

    # @return [Array] all source files with asset tags
    def sources_with_assets
      return [] if config[:assets].nil?
      return [] if config[:assets][:sources].nil?

      @sources_with_assets = []

      opts = {search_backend: options[:search_backend]}
      [:src_pre, :src_post].each do |opt|
        opts[opt] = config[:assets][:options][opt] unless config[:assets][:options][opt].nil?
      end unless config[:assets][:options].nil?

      config[:assets][:sources].each do |path|
        @sources_with_assets << Assets.find_tags(File.join(directory, path), nil, opts)
      end

      @sources_with_assets.flatten
    end

    # Finds all assets in {#sources_with_assets} and
    # generates the assets and updates the sources.
    # @return [Environment] the current environment instance
    def compile_assets
      sources_with_assets.each do |file|
        source = File.read file
        assets.each { |a| a.update_source! source }
        Utils.write_to_file source, file, preserve: true
      end
      self
    end

    private

    # Checks the config file for invalid settings.
    # @todo Refactor this.
    # - Checks that paths are not absolute or use `../` or `~/`.
    def validate_config
      message = 'bad path in config'

      # Checks the option in the asset key.
      def validate_asset_options(opts)
        opts.each do |k, v|
          fail 'bad option in config' if k == :sprockets_options
          fail message if k == :output && !Utils.safe_path?(v)
        end
      end

      @config[:excludes].each do |v|
        fail message unless Utils.safe_path? v
      end unless @config[:excludes].nil?

      @config[:external].each do |k, v|
        next if k == :server

        v.each do |repo|
          fail message unless Utils.safe_path? repo[1]
        end unless v.nil?
      end unless @config[:external].nil?

      @config[:components].each do |k, v|
        # process @config[:components][:base] then go to the next option
        if k == :base
          fail message unless Utils.safe_path? v
          next
        end unless v.nil?

        # process @config[:components][:paths]
        if k == :paths
          v.each do |path|
            fail message unless Utils.safe_path? path[0]
            fail message unless Utils.safe_path? path[1]
          end
        end
      end unless @config[:components].nil?

      @config[:assets].each do |k, v|
        # process @config[:assets][:options] then go to the next option
        if k == :options
          validate_asset_options v
          next
        end unless v.nil?

        # process @config[:assets][:sources] then go to the next option
        if k == :sources
          v.each_with_index do |source, _|
            fail message unless Utils.safe_path? source
          end
          next
        end

        # process each asset type in @config[:assets]
        v.each do |asset_key, asset_value|
          # process :options
          if asset_key == :options
            validate_asset_options asset_value
            next
          end unless asset_value.nil?

          # process each asset path
          asset_value.each_with_index do |path, _|
            fail message unless Utils.safe_path? path
          end if asset_key == :paths
        end
      end unless @config[:assets].nil?

      @config
    end
  end
end
