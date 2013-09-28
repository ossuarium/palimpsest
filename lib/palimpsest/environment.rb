module Palimpsest

  # An environment is populated with the contents of
  # a site's repository at a specified commit.
  # Alternatively, a single directory can be used to populate the environment.
  # The environment's files are rooted in a temporary {#directory}.
  # An environment is the primary way to interact with a site's files.
  #
  # An environment loads a {#config} file from the working {#directory};
  # by default, `palimpsest_config.yml`.
  #
  # Paths are all relative to the working {#directory}.
  #
  # ````yml
  # # example of palimpsest_config.yml
  #
  # # asset settings
  # :assets:
  #   # all options are passed to Assets#options
  #   # options will use defaults set in Palimpsest::Asset::DEFAULT_OPTIONS if unset here
  #   # unless otherwise mentioned, options can be set or overridden per asset type
  #   :options:
  #     # opening and closing brackets for asset source tags
  #     # global option only: cannot be overridden per asset type
  #     :src_pre: "[%"
  #     :src_post: "%]"
  #
  #     # relative directory to save compiled assets
  #     :output: compiled
  #
  #     # assume assets will be served under here
  #     :cdn: https://cdn.example.com/
  #
  #     # compiled asset names include a uniqe hash by default
  #     # this can be toggled off
  #     :hash: false
  #
  #   # directories to scan for files with asset tags
  #   :sources:
  #     # putting assets/stylesheets first would allow asset tags,
  #     # e.g. for images, to be used in your stylesheets
  #     - assets/stylesheets
  #     - public
  #     - app/src
  #
  #   # all other keys are asset types
  #   :javascripts:
  #     :options:
  #       :js_compressor: :uglifier
  #     # these paths are loaded into the sprockets environment
  #     :paths:
  #       - assets/javascripts
  #       - other/javascripts
  #
  #   # this is another asset type which will have it's own namespace
  #   :stylesheets:
  #     :options:
  #       :css_compressor: :sass
  #
  #     :paths:
  #       - assets/stylesheets
  #   # images can be part of the asset pipeline
  #   :images:
  #     :options:
  #       # requires the sprockets-image_compressor gem
  #       :image_compression: true
  #        # options can be overridden per type
  #       :output: images
  #     :paths:
  #       - assets/images
  # ````
  class Environment

    # Default {#options}.
    DEFAULT_OPTIONS = {
      # all environment's temporary directories will be rooted under here
      tmp_dir: '/tmp',

      # prepended to the name of the environment's working directory
      dir_prefix: 'palimpsest_',

      # name of config file to load, relative to environment's working directory
      config_file: 'palimpsest_config.yml'
    }

    # @!attribute site
    #   @return site to build the environment with
    #
    # @!attribute treeish
    #   @return [String] the reference used to pick the commit to build the environment with
    #
    # @!attribute [r] populated
    #   @return [Boolean] true if the site's repo has been extracted
    attr_reader :site, :treeish, :populated

    def initialize site: nil, treeish: 'master', options: {}
      @populated = false
      self.options options
      self.site = site if site
      self.treeish = treeish
    end

    # Uses {DEFAULT_OPTIONS} as initial value.
    # @param options [Hash] merged with current options
    # @return [Hash] current options
    def options options={}
      @options ||= DEFAULT_OPTIONS
      @options = @options.merge options
    end

    # @see Environment#site
    def site= site
      fail RuntimeError, "Cannot redefine 'site' once populated" if populated
      @site = site
    end

    # @see Environment#treeish
    def treeish= treeish
      fail RuntimeError, "Cannot redefine 'treeish' once populated" if populated
      fail TypeError unless treeish.is_a? String
      @treeish = treeish
    end

    # @return [String] the environment's working directory
    def directory
      if @directory.nil?
        name = site.nil? ? '' : site.name
        @directory = Utility.make_random_directory options[:tmp_dir], "#{options[:dir_prefix]}#{name}_"
      else
        @directory
      end
    end

    # Copy the contents of the working directory.
    # @param dest [String] path to copy environment's files to
    # @return [Environment] the current environment instance
    def copy dest: site.path
      FileUtils.cp_r Dir["#{directory}/*"], dest, preserve: true
      self
    end

    # Removes the environment's working directory.
    # @return [Environment] the current environment instance
    def cleanup
      FileUtils.remove_entry_secure directory if @directory
      @directory = nil
      @assets = []
      @components = []
      @populated = false
      self
    end

    # Extracts the site's files from repository to the working directory.
    # @return [Environment] the current environment instance
    def populate from: :auto
      cleanup if populated
      fail RuntimeError, "Cannot populate without 'site'" if site.nil?

      case from
      when :auto
        if site.respond_to?(:repo) ? site.repo : nil
          populate from: :repo
        else
          populate from: :source
        end
      when :repo
        fail RuntimeError, "Cannot populate without 'treeish'" if treeish.empty?
        Utility.extract_repo site.repo, treeish, directory
        @populated = true
      when :source
        FileUtils.cp_r Dir["#{site.source}/*"], directory, preserve: true
        @populated = true
      end

      self
    end

    # @return [Hash] configuration loaded from {#options}`[:config_file]` under {#directory}
    def config
      populate unless populated
      @config = YAML.load_file "#{directory}/#{options[:config_file]}"
      validate_config if @config
    end

    # @return [Array<Component>] components with paths loaded from config
    def components
      return @components if @components
      return [] if config[:components].nil?
      return [] if config[:components][:paths].nil?

      @components = []

      base = directory
      base += config[:components][:base].nil? ? '' : '/' + config[:components][:base]

      config[:components][:paths].each do |paths|
       @components << Component.new(source_path: "#{base}/#{paths[0]}", install_path: "#{directory}/#{paths[1]}")
      end

      @components
    end

    # Install all components.
    # @return [Environment] the current environment instance
    def install_components
      components.each { |c| c.install }
      self
    end

    # @return [Array<Assets>] assets with settings and paths loaded from config
    def assets
      return @assets if @assets

      @assets = []

      config[:assets].each do |type, opt|
        next if [:sources].include? type
        next if opt[:paths].nil?

        assets = Assets.new directory: directory, paths: opt[:paths]
        assets.options config[:assets][:options] unless config[:assets][:options].nil?
        assets.options opt[:options] unless opt[:options].nil?
        assets.type = type
        @assets << assets
      end unless config[:assets].nil?

      @assets
    end

    # @return [Array] all source files with asset tags
    def sources_with_assets
      return [] if config[:assets].nil?
      return [] if config[:assets][:sources].nil?

      @sources_with_assets = []

      opts = {}
      [:src_pre, :src_post].each do |opt|
        opts[opt] = config[:assets][:options][opt] unless config[:assets][:options][opt].nil?
      end unless config[:assets][:options].nil?

      config[:assets][:sources].each do |path|
        @sources_with_assets << Assets.find_tags("#{directory}/#{path}", nil, opts)
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
        Utility.write source, file, preserve: true
      end
      self
    end

    private

    # Checks the config file for invalid settings.
    # @todo refactor this
    # - Checks that paths are not absolute or use `../` or `~/`.
    def validate_config
      message = 'bad path in config'

      # Checks the option in the asset key.
      def validate_asset_options opts
        opts.each do |k,v|
          fail RuntimeError, 'bad option in config' if k == :sprockets_options
          fail RuntimeError, message if k == :output && ! Utility.safe_path?(v)
        end
      end

      @config[:components].each do |k,v|
        # process @config[:components][:base] then go to the next option
        if k == :base
          fail RuntimeError, message unless Utility.safe_path? v
          next
        end unless v.nil?

        # process @config[:components][:paths]
        if k == :paths
          v.each do |path|
            fail RuntimeError, message unless Utility.safe_path? path[0]
            fail RuntimeError, message unless Utility.safe_path? path[1]
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
          v.each_with_index do |source, i|
            fail RuntimeError, message unless Utility.safe_path? source
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
          asset_value.each_with_index do |path, i|
            fail RuntimeError, message unless Utility.safe_path? path
          end
        end
      end unless @config[:assets].nil?

      @config
    end
  end
end
