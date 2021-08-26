# frozen_string_literal: true
require "jekyll"

require_relative "context"
require_relative "converter"
require_relative "doc_manager"
require_relative "link_index"
require_relative "parser"
require_relative "site"

module Jekyll
  module WikiLinks

    class Generator < Jekyll::Generator

      def generate(site)
        return if $conf.disabled?

        @site ||= site
        @context ||= Jekyll::WikiLinks::Context.new(site)

        # setup helper classes
        @parser = Parser.new(@site)
        @site.link_index = LinkIndex.new(@site)

        # parse
        @site.doc_mngr.all.each do |doc|
          @parser.parse(doc.content)
          # attributes are handled alongside parsing since
          # they need access to the parser's discovered 'typed_link_blocks'
          # and remove the text from the document
          @site.link_index.populate_attributes(doc, @parser.typed_link_blocks, @site.doc_mngr.all)
        end
        # build link_index
        # (wait until all docs are processed before assigning metadata,
        # so all backlinks are collected for assignment)
        @site.doc_mngr.all.each do |doc|
          @site.link_index.populate_links(doc, @site.doc_mngr.all)
          @site.link_index.assign_metadata(doc)
        end
      end

    end

  end
end
