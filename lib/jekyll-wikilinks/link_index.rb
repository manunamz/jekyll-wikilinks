require 'jekyll-wikilinks/naming_const' # for REGEX_NOT_GREEDY

module Jekyll
  module WikiLinks

    class LinkIndex
      attr_reader :index

      # Use Jekyll's native relative_url filter
      include Jekyll::Filters::URLFilters

      # identify missing links in doc via .invalid-wiki-link class and nested doc-text.
      REGEX_INVALID_WIKI_LINK = /invalid-wiki-link#{REGEX_NOT_GREEDY}\[\[(#{REGEX_NOT_GREEDY})\]\]/i
      REGEX_VALID_WIKI_LINK = /<a\sclass="wiki-link(\slink-type\s(?<link-type>([^"]+)))?"\shref="(?<link-url>([^"]+))">/i

      def initialize(site, doc_manager)
        @context ||= Jekyll::WikiLinks::Context.new(site)
        @doc_manager ||= doc_manager
        @index = {}
        @doc_manager.all.each do |doc|
          @index[doc.url] = LinksInfo.new()
        end
      end

      def process
        self.populate_links()
        # apply index info to each document
        @doc_manager.all.each do |doc|
          doc.data['attributed'] = @index[doc.url].attributed
          doc.data['attributes'] = @index[doc.url].attributes
          doc.data['backlinks']  = @index[doc.url].backlinks
          doc.data['forelinks']  = @index[doc.url].forelinks
          doc.data['missing']    = @index[doc.url].missing
        end
      end

      def populate_attributes(doc, typed_link_blocks)
        typed_link_blocks.each do |tl|
          attr_doc = @doc_manager.get_doc_by_fname(tl.filename)
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

      def populate_links()
        # for each document...
        @doc_manager.all.each do |doc|
          # ...process its forelinks
          doc.content.scan(REGEX_VALID_WIKI_LINK).each do |m|
            ltype, lurl = m[0], m[1]
            @index[doc.url].forelinks << {
              'type' => ltype,
              'doc_url' => lurl,
            }
          end
          # ...process its backlinks
          @doc_manager.all.each do |doc_to_backlink|
            doc_to_backlink.content.scan(REGEX_VALID_WIKI_LINK).each do |m|
              ltype, lurl = m[0], m[1]
              if lurl == relative_url(doc.url)
                @index[doc.url].backlinks << {
                  'type' => ltype,
                  'doc_url' => doc_to_backlink.url,
                }
              end
            end
            doc_to_backlink.content.scan(REGEX_INVALID_WIKI_LINK).each do |m|
              ltext = m[0]
              @index[doc.url].missing << ltext
            end
          end
        end
      end

      class LinksInfo
        attr_accessor :attributes, :attributed, :backlinks, :forelinks, :missing

        def initialize
          @attributed = [] # block typed backlinks
          @attributes = [] # block typed forelinks
          @backlinks  = []
          @forelinks  = []
          @missing    = [] # missing forelinks
        end
      end
    end

  end
end
