require 'digest/sha1'
require 'zaru'

module Palimpsest

  # Class for working with mirrored git repositories.
  # Supports simple cache.
  class Repo

    include Utils

    # @!attribute source
    #   @return [String] local or remote path to git repository
    #
    # @!attribute cache
    #   @return [String] local root directory to look for cached repositories
    attr_accessor :source, :cache, :local_clone

    def initialize source: nil, cache: "#{Dir.tmpdir}/palimpsest"
      self.source = source
      self.cache = cache
    end

    # Path to place the local clone of the repository.
    # If not set, a unique path will be used under the {#cache}.
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
    # @return [Repo] the repo object
    def mirror
      fail RuntimeError, 'Must specify source.' unless source
      mirror_repo source, local_clone unless Dir.exists? local_clone
      self
    end

    # Update a cached clone.
    # @param path [String] location of local mirror
    # @return [Repo] the repo object
    def update
      mirror
      update_repo local_clone
      self
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
      fail RuntimeError, 'Git not installed' unless command? 'git'
      system 'git', 'clone', '--mirror', source, destination
    end

    # Update a git repository.
    def update_repo path
      fail RuntimeError, 'Git not installed' unless command? 'git'
      Dir.chdir path do
        system 'git', 'remote', 'update'
      end
    end

    # Extract repository files at a particular reference to directory.
    def extract_repo destination, reference
      fail RuntimeError, 'Git not installed' unless command? 'git'
      system "git archive #{reference} | tar -x -C #{destination}"
    end
  end

end

