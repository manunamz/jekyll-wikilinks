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
        @testing ||= config['testing'] if config.keys.include?('testing')
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

        # setup helper classes
        @doc_manager = DocManager.new(@md_docs, @site.static_files)
        @parser = Parser.new(@context, @markdown_converter, @doc_manager)
        @site.link_index = LinkIndex.new(@site, @doc_manager)

        # parse + populate index
        @md_docs.each do |doc|
          @parser.parse(doc.content)
          @site.link_index.populate_attributes(doc, @parser.typed_link_blocks)
        end
        @site.link_index.process
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

      def old_config_warn()
        if @config.include?("wikilinks_collection")
          Jekyll.logger.warn "As of 0.0.3, 'wikilinks_collection' is no longer used for configs. jekyll-wikilinks will scan all markdown files by default. Check README for details."
        end
        if @config.include?("assets_rel_path")
          Jekyll.logger.warn "As of 0.0.5, 'assets_rel_path' is now 'path'."
        end
      end
    end

  end
end
