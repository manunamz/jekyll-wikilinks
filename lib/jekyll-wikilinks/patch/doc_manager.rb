# frozen_string_literal: true
require_relative "../util/regex"

module Jekyll
  module WikiLinks

    #
    # this class is responsible for answering any questions
    # related to jekyll markdown documents
    # that are meant to be processed by the wikilinks plugin
    #
    class DocManager
      CONVERTER_CLASS = Jekyll::Converters::Markdown

      def initialize(site)
        return if $wiki_conf.disabled?

        markdown_converter = site.find_converter_instance(CONVERTER_CLASS)
        # filter docs based on configs
        docs = []
        docs += site.pages if !$wiki_conf.exclude?(:pages)
        docs += site.docs_to_write.filter { |d| !$wiki_conf.exclude?(d.type) }
        @md_docs = docs.filter { |doc| markdown_converter.matches(doc.extname) }
        if @md_docs.nil? || @md_docs.empty?
          Jekyll.logger.debug("No documents to process.")
        end

        @static_files ||= site.static_files
      end

      # accessors

      def all
        return @md_docs
      end

      def get_doc_by_fname(filename)
        return nil if filename.nil? || @md_docs.size == 0
        docs = @md_docs.select{ |d| File.basename(d.basename, File.extname(d.basename)) == filename }
        return nil if docs.nil? || docs.size > 1
        return docs[0]
      end

      def get_doc_by_url(url)
        return nil if url.nil? || @md_docs.size == 0
        docs = @md_docs.select{ |d| d.url == url }
        return nil if docs.nil? || docs.size > 1
        return docs[0]
      end

      def get_doc_content(filename)
        return nil if filename.nil? || @md_docs.size == 0
        docs = @md_docs.select{ |d| File.basename(d.basename, File.extname(d.basename)) == filename }
        return docs[0].content if docs.size == 1
        return nil
      end

      def get_image_by_fname(filename)
        return nil if filename.nil? || @static_files.size == 0 || !SUPPORTED_IMG_FORMATS.any?{ |ext| ext == File.extname(filename).downcase }
        docs = @static_files.select{ |d| File.basename(d.relative_path) == filename }
        return nil if docs.nil? || docs.size > 1
        return docs[0]
      end

      def self.doc_has_header?(doc, header)
        return nil if header.nil?
        # leading + trailing whitespace is ignored when matching headers
        header_results = doc.content.scan(REGEX_ATX_HEADER).flatten.map { |htxt| htxt.strip }
        setext_header_results = doc.content.scan(REGEX_SETEXT_HEADER).flatten.map { |htxt| htxt.strip }
        return header_results.include?(header.strip) || setext_header_results.include?(header.strip)
      end

      def self.doc_has_block_id?(doc, block_id)
        return nil if block_id.nil?
        # leading + trailing whitespace is ignored when matching blocks
        block_id_results = doc.content.scan(REGEX_BLOCK).flatten.map { |bid| bid.strip }
        return block_id_results.include?(block_id)
      end
    end

  end
end
