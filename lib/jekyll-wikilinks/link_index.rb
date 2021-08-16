require 'jekyll-wikilinks/regex' # for REGEX_NOT_GREEDY

module Jekyll
  module WikiLinks

    class LinkIndex
      attr_reader :index

      # Use Jekyll's native relative_url filter
      include Jekyll::Filters::URLFilters

      def initialize(site, md_docs)
        @context ||= Jekyll::WikiLinks::Context.new(site)
        @index = {}
        md_docs.each do |doc|
          @index[doc.url] = LinksInfo.new()
        end
      end

      def assign_metadata(doc)
        doc.data['attributed'] = @index[doc.url].attributed
        doc.data['attributes'] = @index[doc.url].attributes
        doc.data['backlinks']  = @index[doc.url].backlinks
        doc.data['forelinks']  = @index[doc.url].forelinks
        doc.data['missing']    = @index[doc.url].missing
      end

      def populate_attributes(doc, typed_link_blocks, md_docs)
        typed_link_blocks.each do |tl|
          attr_doc = md_docs.detect { |d| File.basename(d.basename, File.extname(d.basename)) == tl.filename }
          if !attr_doc.nil?
            @index[doc.url].attributes << {
              'type' => tl.link_type,
              'doc_url' => attr_doc.url,
            }
            @index[attr_doc.url].attributed << {
              'type' => tl.link_type,
              'doc_url' => doc.url,
            }
          else
            Jekyll.logger.warn("Typed block link's document not found for #{tl.filename}")
          end
        end
      end

      def populate_links(doc, md_docs)
        # ...process its forelinks
        doc.content.scan(REGEX_VALID_WIKI_LINK).each do |m|
          ltype, lurl = m[0], m[1]
          @index[doc.url].forelinks << {
            'type' => ltype,
            'doc_url' => lurl,
          }
        end
        # ...process its backlinks
        # TODO: can probably get rid of this and only add backlink per forelink
        md_docs.each do |doc_to_backlink|
          doc_to_backlink.content.scan(REGEX_VALID_WIKI_LINK).each do |m|
            ltype, lurl = m[0], m[1]
            if lurl == relative_url(doc.url)
              @index[doc.url].backlinks << {
                'type' => ltype,
                'doc_url' => doc_to_backlink.url,
              }
            end
          end
        end
        # ...process missing links
        doc.content.scan(REGEX_INVALID_WIKI_LINK).each do |m|
          ltext = m[0]
          @index[doc.url].missing << ltext
        end
      end

      class LinksInfo
        attr_accessor :attributes, :attributed, :backlinks, :forelinks, :missing

        def initialize
          @attributed = [] # block typed backlinks
          @attributes = [] # block typed forelinks
          @backlinks  = [] # inline typed and basic backlinks
          @forelinks  = [] # inline typed and basic forelinks
          @missing    = [] # missing forelinks
        end
      end
    end

  end
end
