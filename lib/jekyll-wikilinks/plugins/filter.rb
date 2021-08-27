# frozen_string_literal: true

module Jekyll
  module WikiLinks

    module TypeFilters
      # 'links' accepts both untyped links, typed links, and attributes; fore and back.

      # usage: {% assign note_links = page.links | doc_type = "notes" %}
      def doc_type(links, doc_type)
        return if links.nil? || links.empty?

        site = @context.registers[:site]
        links.each do |l|
          doc = site.documents.select{ |d| d.url == l['doc_url'] && d.type.to_s == doc_type.to_s }
          if doc.nil? || doc.size != 1
            links.delete(l)
          end
        end
        return links.uniq
      end

      # usage: {% assign author_links = page.links | link_type = "author" %}
      def link_type(links, link_type)
        return if links.nil? || links.empty?

        site = @context.registers[:site]
        links.each do |l|
          if l['type'].to_s == link_type.to_s
            docs = site.documents.select{ |d| d.url == l['doc_url'] }
            if !docs.nil? && docs.size == 1
              links.delete(l)
            end
          end
        end
        return links.uniq
      end

    end

  end
end
