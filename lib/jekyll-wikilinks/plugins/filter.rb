# frozen_string_literal: true

module Jekyll
  module WikiLinks

    module TypeFilters
      # 'links' accepts untyped links, typed links, and attributes; fore and back.
      # why: these filters are useful when you want to list backlinks of certain type(s) and don't want type mismatches to display as "missing"

      # usage: {% assign note_links = page.links | doc_type: "notes" %}
      def doc_type(links, doc_type)
        Jekyll.logger.error("Jekyll-Wikilinks: 'links' invalid") if links.nil?
        Jekyll.logger.error("Jekyll-Wikilinks: 'doc_type' invalid") if doc_type.nil? || doc_type.empty?
        return [] if links.empty?

        site = @context.registers[:site]

        links_of_type = []
        links.each do |l|
          # links
          if l.keys.include?('url')
            docs = site.documents.select{ |d| d.url == l['url'] && d.type.to_s == doc_type.to_s }
            if !docs.nil? && docs.size == 1
              links_of_type << l
            end
          # attributes
          elsif l.keys.include?('urls')
            l['urls'].each do |lurl|
              docs = site.documents.select{ |d| d.url == lurl && d.type.to_s == doc_type.to_s }
              if !docs.nil? && docs.size == 1
                links_of_type << l
              end
            end
          else
            Jekyll.logger.error("Jekyll-Wikilinks: In 'doc_type' filter, 'links' do not have 'url' or 'urls'")
          end
        end
        return links_of_type.uniq
      end

      # usage: {% assign author_links = page.links | rel_type: "author" %}
      def rel_type(links, link_type)
        Jekyll.logger.error("Jekyll-Wikilinks: 'links' invalid") if links.nil?
        Jekyll.logger.error("Jekyll-Wikilinks: 'link_type' invalid") if link_type.nil?
        return [] if links.empty?

        site = @context.registers[:site]

        links_of_type = []
        links.each do |l|
          if l['type'].to_s == link_type.to_s
            # links
            if l.keys.include?('url')
              docs = site.documents.select{ |d| d.url == l['url'] }
              if !doc.nil? && docs.size != 1
                links_of_type << l
              end
            # attributes
            elsif l.keys.include?('urls')
              all_docs_exist = true
              l['urls'].each do |lurl|
                docs = site.documents.select{ |d| d.url == lurl }
                if !docs.nil? && docs.size != 1
                  all_docs_exist = false
                end
              end
              if all_docs_exist
                links_of_type << l
              end
            else
              Jekyll.logge.error("Jekyll-Wikilinks: In 'rel_type' filter, 'links' do not have 'url' or 'urls'")
            end
          end
        end
        return links_of_type.uniq
      end

    end

  end
end
