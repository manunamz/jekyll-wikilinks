# frozen_string_literal: true

module JekyllWikiLinks
  class Context
    attr_reader :site

    def initialize(site)
      @site = site
    end

    def registers
      { :site => site }
    end
  end
end
