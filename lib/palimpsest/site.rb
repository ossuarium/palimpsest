module Palimpsest

  # Model site object used by {Environment#site}.
  class Site

    # @!attribute name
    #   @return [String] name for this site
    #
    # @!attribute repo
    #   @return [Grit::Repo] grit repo for this site
    #
    # @!attribute source
    #   @return [String] path to source code for this site
    attr_accessor :name, :repo, :source, :path

    def initialize name: '', repo: nil, source: ''
      self.name = name
      self.repo = repo
      self.source = source
      self.path = path
    end
  end
end
