# frozen_string_literal: true
require "jekyll"

require_relative "jekyll-wikilinks/config"
require_relative "jekyll-wikilinks/context"
require_relative "jekyll-wikilinks/converter"
require_relative "jekyll-wikilinks/doc_manager"
require_relative "jekyll-wikilinks/filter"
require_relative "jekyll-wikilinks/link_index"
require_relative "jekyll-wikilinks/parser"
require_relative "jekyll-wikilinks/site"
require_relative "jekyll-wikilinks/version"

Jekyll::Hooks.register :site, :after_init do |site|
  $conf = Jekyll::WikiLinks::PluginConfig.new(site.config)
end

Liquid::Template.register_filter(Jekyll::WikiLinks::TypeFilters)

module Jekyll
  module WikiLinks

    class Generator < Jekyll::Generator
      # for testing
      # attr_reader :config

      # Use Jekyll's native relative_url filter
      include Jekyll::Filters::URLFilters

      CONVERTER_CLASS = Jekyll::Converters::Markdown

      def generate(site)
        return if $conf.disabled?
        # Jekyll.logger.debug "Excluded jekyll types: ", option(EXCLUDE_KEY)

        # setup site
        @site ||= site
        @context ||= Jekyll::WikiLinks::Context.new(site)

        # setup markdown docs
        docs = []
        docs += @site.pages if !$conf.exclude?(:pages)
        docs += @site.docs_to_write.filter { |d| !$conf.exclude?(d.type) }
        @md_docs = docs.filter {|doc| markdown_extension?(doc.extname) }

        if @md_docs.empty?
          Jekyll.logger.debug("No documents to process.")
        end

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

      # helpers

      def markdown_extension?(extension)
        markdown_converter.matches(extension)
      end

      def markdown_converter
        @markdown_converter ||= @site.find_converter_instance(CONVERTER_CLASS)
      end

    end

  end
end
