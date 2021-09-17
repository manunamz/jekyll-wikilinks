# frozen_string_literal: true
require "jekyll"

require_relative "../patch/context"
require_relative "../patch/doc_manager"
require_relative "../patch/site"
require_relative "../util/link_index"
require_relative "../util/parser"
require_relative "converter"

module Jekyll
  module WikiLinks

    class Generator < Jekyll::Generator

      def generate(site)
        return if $wiki_conf.disabled?

        @site ||= site
        @context ||= Jekyll::WikiLinks::Context.new(site)

        # setup helper classes
        @parser = Parser.new(@site)
        @site.link_index = LinkIndex.new(@site)

        @site.doc_mngr.all.each do |doc|
          @parser.parse(doc.content)
          @site.link_index.populate_forward(doc, @parser.wikilink_blocks, @parser.wikilink_inlines, @site.doc_mngr.all)
        end
        # wait until all docs are processed before assigning backward facing metadata,
        # this ensures all attributed/backlinks are collected for assignment
        @site.doc_mngr.all.each do |doc|
          @site.link_index.populate_backward(doc, @site.doc_mngr.all)
          @site.link_index.assign_metadata(doc)
        end
      end

    end

  end
end
