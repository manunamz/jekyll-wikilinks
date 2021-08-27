require_relative 'regex'

module Jekyll
  module WikiLinks

    class LinkIndex
      attr_reader :index

      # Use Jekyll's native relative_url filter
      include Jekyll::Filters::URLFilters

      def initialize(site)
        @baseurl = site.baseurl
        @context ||= Jekyll::WikiLinks::Context.new(site)
        @index = {}
        site.doc_mngr.all.each do |doc|
          @index[doc.url] = LinksInfo.new()
        end
      end

      def assign_metadata(doc)
        doc.data['attributed'] = @index[doc.url].attributed.uniq
        doc.data['attributes'] = @index[doc.url].attributes.uniq
        doc.data['backlinks']  = @index[doc.url].backlinks.uniq
        doc.data['forelinks']  = @index[doc.url].forelinks.uniq
        doc.data['missing']    = @index[doc.url].missing.uniq
      end

      def populate_forward(doc, typed_link_blocks, md_docs)
        # attributes
        typed_link_blocks.each do |tlb|
          attr_doc = md_docs.detect { |d| File.basename(d.basename, File.extname(d.basename)) == tlb.filename }
          if !attr_doc.nil?
            @index[doc.url].attributes << {
              'type' => tlb.link_type,
              'url' => attr_doc.url,
            }
          else
            Jekyll.logger.warn("Typed block link's document not found for #{tlb.filename}")
          end
        end
        # forelinks
        doc.content.scan(REGEX_VALID_WIKI_LINK).each do |m|
          ltype, lurl = m[0], m[1]
          link_doc = md_docs.detect{ |d| d.url == self.remove_baseurl(lurl) }
          if !link_doc.nil?
            @index[doc.url].forelinks << {
              'type' => ltype,
              'url' => lurl,
            }
          end
        end
        # ...process missing links
        doc.content.scan(REGEX_INVALID_WIKI_LINK).each do |m|
          ltext = m[0]
          @index[doc.url].missing << ltext
        end
      end

      def populate_backward(doc, md_docs)
        md_docs.each do |doc_to_link|
          # attributed
          @index[doc_to_link.url].attributes.each do |al|
            if self.remove_baseurl(al['url']) == doc.url
              @index[doc.url].attributed << {
                'type' => al['type'],
                'url' => doc_to_link.url,
              }
            end
          end
          # backlinks
          @index[doc_to_link.url].forelinks.each do |l|
            if self.remove_baseurl(l['url']) == doc.url
              @index[doc.url].backlinks << {
                'type' => l['type'],
                'url' => doc_to_link.url,
              }
            end
          end
        end
      end

      def remove_baseurl(url)
        return url.gsub(@baseurl, '') if !@baseurl.nil?
        return url
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
