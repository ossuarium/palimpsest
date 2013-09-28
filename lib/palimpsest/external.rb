module Palimpsest

  # Use this class to manage external repositories you want to include in your project.
  #
  # Given a name, source and branch, the contents of the repository at the HEAD of the branch
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
    # @!attribute branch
    #   @return [String] branch to use for treeish
    #
    # @!attribute install_path
    #   @return [String] where the files will be installed to
    attr_accessor :name, :source, :branch, :install_path

    def initialize name: '', source: '', branch: 'master', install_path: ''
      self.name = name
      self.source = source
      self.branch = branch
      self.install_path = install_path
    end

    # @return [String] full path to repo as {#source}`/`{#name}
    def repo_path
      ( source.empty? || name.empty? ) ? '' : "#{source}/#{name}"
    end

    # @return [Environment] environment with contents of the repository at the HEAD of the branch
    def environment
      return @environment if @environment

      site = Site.new name: "external_#{name.gsub '/', '_'}", repo: Grit::Repo.new(tmp_environment.directory)
      @environment = Environment.new site: site, treeish: branch
    end

    # Copy the files to the {#install_path}.
    # @return (see Environment#copy)
    def install
      environment.populate.copy dest: install_path
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

      fail RuntimeError if repo_path.empty?

      Grit::Git.git_max_size = 200 * 1048576
      Grit::Git.git_timeout = 200

      @tmp_environment = Environment.new site: Site.new(name: "external_clone_#{name.gsub '/', '_'}")
      gritty = Grit::Git.new tmp_environment.directory
      gritty.clone( { branch: branch }, repo_path, tmp_environment.directory )
      @tmp_environment
    end
  end
end
