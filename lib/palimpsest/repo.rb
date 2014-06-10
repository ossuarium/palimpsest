require 'digest/sha1'
require 'zaru'

module Palimpsest

  # Class for working with mirrored git repositories.
  # Supports simple cache.
  class Repo

    # @!attribute source
    #   @return [String] local or remote path to git repository
    #
    # @!attribute cache
    #   @return [String] local root directory to look for cached repositories
    #
    # @!attribute auth
    #   @return [Hash] any information required for authentication
    attr_accessor :source, :cache, :auth, :local_clone

    def initialize source: nil, cache: "#{Dir.tmpdir}/palimpsest", auth: {}
      self.source = source
      self.cache = cache
      self.auth = auth
    end

    def local_clone
      return @local_clone if @local_clone
      return nil if cache.nil?
      return nil if source.nil?
      hash = Digest::SHA1.hexdigest(source)[0..10]
      path = Zaru.sanitize! source.gsub(%r([/\\:]), '_')
      File.join cache, "repo_#{path}_#{hash}"
    end

    # Create a bare mirrored clone.
    # @param destination [String] where to place the repository
    # @return [String] path to new mirror
    def mirror
      fail RuntimeError, 'Must specify source.' unless source
      mirror_repo source, local_clone unless Dir.exists? local_clone
      local_clone
    end

    # Update a cached clone.
    # @param path [String] location of local mirror
    def update
      mirror
      update_repo local_clone
    end

    # Extracts the repository files at a particular reference to directory.
    # @param destination [String] directory to place files
    # @param reference [String] the git reference to use
    def extract destination, reference: 'master'
      update
      extract_repo destination, reference
    end

    private

    # Create a git mirrored clone.
    def mirror_repo source, destination
    end

    # Update a git repository.
    def update_repo path
    end

    # Extract repository files at a particular reference to directory.
    def extract_repo destination, reference
    end
  end

end

