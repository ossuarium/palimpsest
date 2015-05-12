module Palimpsest
  # Use this class to store parts of your project in a location
  # separate from the normal installed location.
  #
  # For example, put custom templates in `components/my_app/templates`
  # which might later be installed to `apps/my_app/templates`.
  #
  # This is useful when `apps/my_app` is a separate project
  # with its own repository loaded using {Palimpsest::External}.
  class Component
    # @!attribute source_path
    #   @return [String] source path for component
    #
    # @!attribute install_path
    #   @return [String] install path for component
    attr_accessor :source_path, :install_path

    def initialize(source_path: nil, install_path: nil)
      self.source_path = source_path
      self.install_path = install_path
    end

    # Installs files in {#source_path} to {#install_path}
    def install
      fail if source_path.nil?
      fail if install_path.nil?
      FileUtils.mkdir_p install_path
      Palimpsest::Utils.copy_directory source_path, install_path
    end
  end
end
