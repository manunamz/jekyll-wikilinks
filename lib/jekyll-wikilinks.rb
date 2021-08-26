# frozen_string_literal: true
require "jekyll"

require_relative "jekyll-wikilinks/config"
require_relative "jekyll-wikilinks/filter"
require_relative "jekyll-wikilinks/generator"
require_relative "jekyll-wikilinks/version"

Jekyll::Hooks.register :site, :after_init do |site|
  $conf = Jekyll::WikiLinks::PluginConfig.new(site.config)
end

# Jekyll.logger.debug "Excluded jekyll types: ", option(EXCLUDE_KEY)

Jekyll::Hooks.register :site, :post_read do |site|
  site.doc_mngr = Jekyll::WikiLinks::DocManager.new(site)
  # # setup helper classes
  # @parser = Parser.new(@site)
  # @site.link_index = LinkIndex.new(@site)
end

Liquid::Template.register_filter(Jekyll::WikiLinks::TypeFilters)

module Jekyll
  module WikiLinks
  end
end
