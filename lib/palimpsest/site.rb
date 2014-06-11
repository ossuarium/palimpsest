module Palimpsest

  # Model site object used by {Environment#site}.
  class Site

    # @!attribute name
    #   @return [String] name for this site
    #
    # @!attribute repository
    #   @return [Grit::Repo] local or remote path to git repository for this site
    #
    # @!attribute source
    #   @return [String] path to source code for this site
    #
    # @!attribute path
    #   @return [String] path to destination for this site
    attr_accessor :name, :repository, :source, :path

    def initialize name: '', repository: nil, source: nil
      self.name = name
      self.repository = repository
      self.source = source
      self.path = path
    end
  end
end
