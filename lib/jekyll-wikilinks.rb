# frozen_string_literal: true
require "jekyll"

require_relative "jekyll-wikilinks/version"

# in order of expected execution

# setup config
require_relative "jekyll-wikilinks/config"
Jekyll::Hooks.register :site, :after_init do |site|
  # global '$wiki_conf' to ensure that all local jekyll plugins
  # are reading from the same configuration
  # (global var is not ideal, but is DRY)
  $wiki_conf = Jekyll::WikiLinks::PluginConfig.new(site.config)
end

# setup docs (based on configs)
require_relative "jekyll-wikilinks/patch/doc_manager"
Jekyll::Hooks.register :site, :post_read do |site|
  if !$wiki_conf.disabled?
    site.doc_mngr = Jekyll::WikiLinks::DocManager.new(site)
  end
end

# convert
require_relative "jekyll-wikilinks/plugins/converter"

# generate
require_relative "jekyll-wikilinks/plugins/generator"

# convert fores
# Jekyll::Hooks.register :documents, :pre_convert do |doc|
#   Jekyll:WikiLinks::Parser.parse_blocks(doc)
#   @site.link_index.populate_fores(doc, typed_link_blocks, md_docs)
# end

# convert backs
# Jekyll::Hooks.register :documents, :pre_convert do |doc|
#   Jekyll:WikiLinks::Parser.parse_inlines(doc)
#   @site.link_index.populate_backs(doc, typed_link_blocks, md_docs)
# end

# generate metadata
# Jekyll::Hooks.register :documents, :post_convert do |doc|
#   Jekyll:WikiLinks::Generator.generate(doc)
# end

# hook up liquid filters
require_relative "jekyll-wikilinks/plugins/filter"
Liquid::Template.register_filter(Jekyll::WikiLinks::TypeFilters)
