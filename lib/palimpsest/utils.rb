require 'mkmf'
require 'open3'

module Palimpsest

  # Utility module.
  module Utils

    # Available backends for {#copy_directory}.
    COPY_BACKENDS = %i(rsync)

    # Available backends for {#search_files}.
    FILE_SEARCH_BACKENDS = %i(grep)

    # Write contents to file.
    # @param contents [String]
    # @param file [String]
    def write_to_file contents, file, preserve: false
      original_time = File.mtime file if preserve
      File.open(file, 'w') { |f| f.write contents }
      File.utime original_time, original_time, file if preserve
    end

    # Copy contents of a directory.
    # When using the `:rsync` backend,
    # `exclude` should be a list of rsync exclude patterns.
    # @param source [String] directory to copy
    # @param destination [String] where to copy contents of the directory
    # @param exclude [Symbol] files and directories to exclude from copy
    # @param mirror [Boolean] remove any non-excluded paths from destination
    # @param backend [Symbol] copy backed to use
    def copy_directory source, destination, exclude: [], mirror: false, backend: :auto
      available_backends = backends(COPY_BACKENDS)
      backend = available_backends.first if backend == :auto
      fail RuntimeError, 'Requested copy backend not available.' unless available_backends.include? backend
      send "copy_directory_with_#{backend}".to_sym, source, destination, exclude: exclude, mirror: mirror
    end

    # Search all non-binary files against regular expression.
    # When using the `:grep` backend,
    # `regex` should be an extended regular expression as a string.
    # @param regex [Regexp, String] regular expression to match
    # @param path [String] where to search
    # @param backend [Symbol] search backed to use
    # @return [Array] matched files
    def search_files regex, path, backend: :auto
      available_backends = backends(FILE_SEARCH_BACKENDS)
      backend = available_backends.first if backend == :auto
      fail RuntimeError, 'Requested search backend not available.' unless available_backends.include? backend
      send "search_files_with_#{backend}".to_sym, regex, path
    end

    # Forbids use of `../` and `~/` in path.
    # Forbids absolute paths.
    # @param path [String]
    # @return [Boolean]
    def safe_path? path
      case
      when path[/(\.\.\/|~\/)/] then return false
      when path[/^\//] then return false
      else return true
      end
    end

    private

    # Checks if command exists.
    # @param command [String] command name to check
    # @return [String, nil] full path to command or nil if not found
    def command? command
      MakeMakefile::Logging.instance_variable_set :@logfile, File::NULL
      MakeMakefile::Logging.quiet = true
      MakeMakefile.find_executable command.to_s
    end

    # Determines available backends from list of commands
    # by checking if each command exists.
    # The backend `:stdlib` is always available if given.
    def backends commands
      backends = []
      commands.each do |backend|
        backends << backend if command?(backend) || backend == :stdlib
      end
      backends
    end

    #
    # Backend specific methods below.
    #

    # @todo Add support for stdlib backend.
    def copy_directory_with_stdlib source, destination, exclude: [], mirror: false
      fail RuntimeError, "Directory copy via stdlib not yet implemented."
    end

    def copy_directory_with_rsync source, destination, exclude: [], mirror: false
      cmd = %w(rsync -rt)
      cmd << '--del' if mirror
      exclude.each { |e| cmd << %Q{--exclude=#{e}} }
      cmd << "#{source}/"
      cmd << destination
      system *cmd
    end

    # @todo Add support for stdlib backend.
    def search_files_with_stdlib source, destination, exclude: []
      fail RuntimeError, "File search via stdlib not yet implemented."
    end

    def search_files_with_grep regex, path
      fail RuntimeError, "Must specify regex as string." unless regex.is_a? String

      cmd = [command]
      cmd.concat %w(-l -I -r -E)
      cmd << regex
      cmd << path

      files = []
      Open3.capture2(*cmd).first.each_line { |l| files << l.chomp unless l.empty? }
      files
    end
  end

end
