require 'archive/tar/minitar'

module Palimpsest

  # Utility functions for Palimpsest.
  class Utility

    # Make a random directory.
    # @param [String] root directory to place random directory
    # @param [String] prefix prepended to random directory name
    # @param [String, nil] dir the random directory name (used recursively)
    # @return [String] path to created random directory
    def self.make_random_directory root, prefix, dir = nil
      path = "#{root}/#{prefix}#{dir}" unless dir.nil?
      if path.nil? or File.exists? path
        make_random_directory root, prefix, Random.rand(10000000)
      else
        FileUtils.mkdir(path).first
      end
    end

    # Forbids use of `../` and `~/` in path.
    # Forbids absolute paths.
    # @param [String] path
    # @return [Boolean]
    def self.safe_path? path
      case
      when path[/(\.\.\/|~\/)/] then return false
      when path[/^\//] then return false
      else return true
      end
    end

    # Checks that a path is really rooted under a given root directory.
    # Forbids use of `../` and `~/` in path.
    # @param [String] path
    # @param [String] root directory where path should be rooted under
    # @return [String] input path if valid
    def self.validate_path path, root=''
      case
      when path[/(\.\.\/|~\/)/] then fail RuntimeError
      when File.expand_path(path, root)[/^#{root}/].nil? then fail RuntimeError
      else path
      end
    end

    # Extracts a git repo to a directory.
    # @param [Grit::Repo] repo
    # @param [String] treeish
    # @param [String] directory
    def self.extract_repo repo, treeish, directory
      input = Archive::Tar::Minitar::Input.new StringIO.new(repo.archive_tar treeish)
      input.each { |e| input.extract_entry directory, e }
    end

    # Write contents to file.
    # @param contents [String]
    # @param file [String]
    def self.write contents, file, preserve: false
      original_time = File.mtime file if preserve
      File.open(file, 'w') { |f| f.write contents }
      File.utime original_time, original_time, file if preserve
    end
  end
end
