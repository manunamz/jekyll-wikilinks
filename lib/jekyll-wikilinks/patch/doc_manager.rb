# frozen_string_literal: true
require_relative "../util/regex"

module Jekyll
  module WikiLinks

    #
    # this class is responsible for answering any questions
    # related to jekyll markdown documents
    # that are meant to be processed by the wikilinks plugin.
    #
    # the following methods are specifically to address two things:
    #  1. ruby's 'find' / 'detect' function does not throw errors if 
    #     there are multiple matches. fail fast, i want to know if there
    #     are duplicates.
    #  2. handle all jekyll documents in one place. i don't want to
    #     have to filter all documents for target markdown documents 
    #     every time i need to check if a file exists.
    # 
    # there is probably a better way to do this...i would prefer to have
    # a plugin-wide function that just wraps all of this and can be called
    # from anywhere in the plugin...but ruby is not a functional language...
    # gotta have classes...
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
        Jekyll.logger.error "Must provide a 'filename'" if filename.nil? || filename.empty?
        docs = @md_docs.select{ |d| File.basename(d.basename, File.extname(d.basename)) == filename }
        return nil if docs.nil? || docs.empty? || docs.size > 1
        return docs[0]
      end

      def get_doc_by_url(url)
        Jekyll.logger.error "Must provide a 'url'" if url.nil? || url.empty?
        docs = @md_docs.select{ |d| d.url == url }
        return nil if docs.nil? || docs.empty? || docs.size > 1
        return docs[0]
      end

      def get_doc_content(filename)
        Jekyll.logger.error "Must provide a 'filename'" if filename.nil? || filename.empty?
        docs = @md_docs.select{ |d| File.basename(d.basename, File.extname(d.basename)) == filename }
        return docs[0].content if docs.size == 1
        return nil
      end

      def get_image_by_fname(filename)
        Jekyll.logger.error "Must provide a 'filename'" if filename.nil? || filename.empty?
        return nil if @static_files.size == 0 || !SUPPORTED_IMG_FORMATS.any?{ |ext| ext == File.extname(filename).downcase }
        docs = @static_files.select{ |d| File.basename(d.relative_path) == filename }
        return nil if docs.nil? || docs.empty? || docs.size > 1
        return docs[0]
      end

      # validators

      def file_exists?(filename)
        Jekyll.logger.error "Must provide a 'filename'" if filename.nil? || filename.empty?
        docs = @md_docs.select{ |d| File.basename(d.basename, File.extname(d.basename)) == filename }
        docs += @static_files.select{ |d| File.basename(d.relative_path) == filename }
        return false if docs.nil? || docs.empty? || docs.size > 1
        return true
      end

      def doc_has_header?(doc, header)
        Jekyll.logger.error "Must provide a 'header'" if header.nil? || header.empty?
        # leading + trailing whitespace is ignored when matching headers
        header_results = doc.content.scan(REGEX_ATX_HEADER).flatten.map { |htxt| htxt.strip }
        setext_header_results = doc.content.scan(REGEX_SETEXT_HEADER).flatten.map { |htxt| htxt.strip }
        return header_results.include?(header.strip) || setext_header_results.include?(header.strip)
      end

      def doc_has_block_id?(doc, block_id)
        Jekyll.logger.error "Must provide a 'block_id'" if block_id.nil? || block_id.empty?
        # leading + trailing whitespace is ignored when matching blocks
        block_id_results = doc.content.scan(REGEX_BLOCK).flatten.map { |bid| bid.strip }
        return block_id_results.include?(block_id)
      end
    end

  end
end
