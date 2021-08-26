# frozen_string_literal: true
require "jekyll"

require_relative "jekyll-wikilinks/version"

# in order of expected execution

# setup config
require_relative "jekyll-wikilinks/config"
Jekyll::Hooks.register :site, :after_init do |site|
  $conf = Jekyll::WikiLinks::PluginConfig.new(site.config)
end
# setup docs (based on configs)
require_relative "jekyll-wikilinks/doc_manager"
Jekyll::Hooks.register :site, :post_read do |site|
  if !$conf.disabled?
    site.doc_mngr = Jekyll::WikiLinks::DocManager.new(site)
  end
end
# convert
require_relative "jekyll-wikilinks/converter"
# generate
require_relative "jekyll-wikilinks/generator"
# hook up liquid filters
require_relative "jekyll-wikilinks/filter"
Liquid::Template.register_filter(Jekyll::WikiLinks::TypeFilters)
