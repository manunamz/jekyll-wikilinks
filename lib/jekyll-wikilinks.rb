# frozen_string_literal: true
require "jekyll"

require_relative "jekyll-wikilinks/config"
require_relative "jekyll-wikilinks/filter"
require_relative "jekyll-wikilinks/generator"
require_relative "jekyll-wikilinks/version"

Jekyll::Hooks.register :site, :after_init do |site|
  $conf = Jekyll::WikiLinks::PluginConfig.new(site.config)
end

Liquid::Template.register_filter(Jekyll::WikiLinks::TypeFilters)

module Jekyll
  module WikiLinks
  end
end
