module Palimpsest

  # Use this class to manage external repositories you want to include in your project.
  #
  # Given a source and branch, the contents of the repository at the HEAD of the branch
  # will be available as an {Environment} object through {#environment}.
  #
  # Use {#cleanup} to remove all files created by the {#External} object.
  class External

    # @!attribute source
    #   @return [String] source url or path to external git  repo
    #
    # @!attribute branch
    #   @return [String] branch to use for treeish
    attr_accessor :source, :branch

    def initialize source: '', branch: 'master'
      self.source = source
      self.branch = branch
    end

    # @return [Environment] environment with contents of the repository at the HEAD of the branch
    def environment
      return @environment if @environment

      site = Site.new repo: Grit::Repo.new(tmp_environment.directory)
      @environment = Environment.new site: site, treeish: branch
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

      fail RuntimeError if source.empty?

      Grit::Git.git_max_size = 200 * 1048576
      Grit::Git.git_timeout = 200

      @tmp_environment = Environment.new
      gritty = Grit::Git.new tmp_environment.directory
      gritty.clone( { branch: branch }, source, tmp_environment.directory )
      @tmp_environment
    end
  end
end
