# frozen_string_literal: true
require "jekyll"

require_relative "jekyll-wikilinks/context"
require_relative "jekyll-wikilinks/doc_manager"
require_relative "jekyll-wikilinks/filter"
require_relative "jekyll-wikilinks/link_index"
require_relative "jekyll-wikilinks/parser"
require_relative "jekyll-wikilinks/site"
require_relative "jekyll-wikilinks/version"

Liquid::Template.register_filter(Jekyll::WikiLinks::TypeFilters)


module Jekyll
  module WikiLinks

    class Generator < Jekyll::Generator
      # for testing
      attr_reader :config

      # Use Jekyll's native relative_url filter
      include Jekyll::Filters::URLFilters

      CONVERTER_CLASS = Jekyll::Converters::Markdown
      # config
      CONFIG_KEY = "wikilinks"
      ENABLED_KEY = "enabled"
      EXCLUDE_KEY = "exclude"

      def initialize(config)
        @config ||= config
      end

      def generate(site)
        return if disabled?
        self.old_config_warn()
        Jekyll.logger.debug "Excluded jekyll types: ", option(EXCLUDE_KEY)

        # setup site
        @site = site
        @context ||= Jekyll::WikiLinks::Context.new(site)

        # setup markdown docs
        docs = []
        docs += @site.pages if !exclude?(:pages)
        docs += @site.docs_to_write.filter { |d| !exclude?(d.type) }
        @md_docs = docs.filter {|doc| markdown_extension?(doc.extname) }
        return if @md_docs.empty?

        # setup helper classes
        @doc_manager = DocManager.new(@md_docs, @site.static_files)
        @parser = Parser.new(@context, @markdown_converter, @doc_manager)
        @site.link_index = LinkIndex.new(@site, @md_docs)

        # parse
        @md_docs.each do |doc|
          @parser.parse(doc.content)
          # attributes are handled alongside parsing since
          # they need access to the parser's discovered 'typed_link_blocks'
          # and remove the text from the document
          @site.link_index.populate_attributes(doc, @parser.typed_link_blocks, @md_docs)
        end
        # build link_index
        # (wait until all docs are processed before assigning metadata,
        # so all backlinks are collected for assignment)
        @md_docs.each do |doc|
          @site.link_index.populate_links(doc, @md_docs)
          @site.link_index.assign_metadata(doc)
        end
      end

      # config helpers

      def disabled?
        option(ENABLED_KEY) == false
      end

      def exclude?(type)
        return false unless option(EXCLUDE_KEY)
        return option(EXCLUDE_KEY).include?(type.to_s)
      end

      def markdown_extension?(extension)
        markdown_converter.matches(extension)
      end

      def markdown_converter
        @markdown_converter ||= @site.find_converter_instance(CONVERTER_CLASS)
      end

      def option(key)
        @config[CONFIG_KEY] && @config[CONFIG_KEY][key]
      end

      # !! deprecated !!

      def option_exist?(key)
        @config[CONFIG_KEY] && @config[CONFIG_KEY].include?(key)
      end

      def old_config_warn()
        if @config.include?("wikilinks_collection")
          Jekyll.logger.warn "As of 0.0.3, 'wikilinks_collection' is no longer used for configs. jekyll-wikilinks will scan all markdown files by default. Check README for details."
        end
        if option_exist?("assets_rel_path")
          Jekyll.logger.warn "As of 0.0.5, 'assets_rel_path' is now 'path'."
        end
        if @config.include?("d3_graph_data")
          Jekyll.logger.warn "As of 0.0.6, 'd3_graph_data' should now be 'd3' and requires the 'jekyll-d3' plugin."
        end
      end
    end

  end
end
