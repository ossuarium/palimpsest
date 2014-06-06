module Palimpsest

  # Use this class to manage external repositories you want to include in your project.
  #
  # Given a name, source, and ref, the contents of the repository at the HEAD of the ref
  # will be available as an {Environment} object through {#environment}.
  #
  # Use {#cleanup} to remove all files created by the {#External} object.
  class External

    # @!attribute name
    #   @return [String] repository name
    #
    # @!attribute source
    #   @return [String] base source url or path to external git repo (without name)
    #
    # @!attribute ref
    #   @return [String] ref to use for
    #
    # @!attribute install_path
    #   @return [String] where the files will be installed to
    attr_accessor :name, :source, :ref, :install_path

    def initialize name: '', source: nil, ref: 'master', install_path: nil
      self.name = name
      self.source = source
      self.ref = ref
      self.install_path = install_path
    end

    # @return [String] full path to repo as {#source}`/`{#name}
    def repo_path
      ( source.nil? || name.empty? ) ? nil : "#{source}/#{name}"
    end

    # @return [Environment] environment with contents of the repository at the HEAD of the ref
    def environment
      return @environment if @environment

      site = Site.new name: "external_#{name.gsub '/', '_'}", repo: Grit::Repo.new(tmp_environment.directory)
      @environment = Environment.new site: site, treeish: ref
    end

    # Copy the files to the {#install_path}.
    # @return (see Environment#copy)
    def install
      environment.populate.copy destination: install_path
      self
    end

    # @return [External] the current external instance
    def cleanup
      environment.cleanup if @environment
      @environment = nil

      tmp_environment.cleanup if @tmp_environment
      @tmp_environment = nil
      self
    end

    # @return [Environment] temporary environment to hold the cloned repository
    def tmp_environment
      return @tmp_environment if @tmp_environment

      fail RuntimeError if repo_path.nil?

      Grit::Git.git_max_size = 200 * 1048576
      Grit::Git.git_timeout = 200

      @tmp_environment = Environment.new site: Site.new(name: "external_clone_#{name.gsub '/', '_'}")
      gritty = Grit::Git.new tmp_environment.directory
      gritty.clone( {}, repo_path, tmp_environment.directory )
      @tmp_environment
    end
  end
end
