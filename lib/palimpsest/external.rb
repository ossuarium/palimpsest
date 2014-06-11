module Palimpsest

  # Use this class to manage external repositories you want to include in your project.
  #
  # Given a name, source, and reference, you can install
  # the contents of the repository at the reference to the install path.
  class External

    # @!attribute name
    #   @return [String] repository name
    #
    # @!attribute source
    #   @return [String] base source url or path to external git repo (without name)
    #
    # @!attribute reference
    #   @return [String] git reference to use
    #
    # @!attribute install_path
    #   @return [String] where the files will be installed to
    #
    # @!attribute cache
    #   @return [String] local root directory to look for cached repositories
    attr_accessor :name, :source, :reference, :install_path, :cache

    def initialize name: '', source: nil, reference: 'master', install_path: nil, cache: File.join(Dir.tmpdir, 'palimpsest')
      self.name = name
      self.source = source
      self.reference = reference
      self.install_path = install_path
      self.cache = cache
    end

    # @return [String] full path to repo as {#source}`/`{#name}
    def repository_path
      return nil if source.nil? || name.empty?

      path = File.join source, name
      if Dir.exists? path
        path
      else
        "#{source}/#{name}"
      end
    end

    # The corresponding {Repo} for this external.
    def repo
      @repo = nil if repository_path != @repo.source unless @repo.nil?
      @repo = nil if cache != @repo.cache unless @repo.nil?
      @repo ||= Repo.new.tap do |r|
        r.cache = cache
        r.source = repository_path
      end
    end

    # Copy the files to the {#install_path}.
    # @return [External] this external object
    def install
      fail RuntimeError, 'Must specify an install path.' unless install_path
      FileUtils.mkdir_p install_path
      repo.extract install_path, reference: reference
      self
    end
  end
end
