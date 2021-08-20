# frozen_string_literal: true

module Jekyll
  module WikiLinks

    module TypeFilters
      # 'links' accepts both untyped links, typed links, and attributes; fore and back.

      # usage: {% assign note_links = page.links | doc_type = "notes" %}
      # "doc_type" is the jekyll type ("pages", "posts", "<collection-name>")
      def doc_type(links, doc_type)
        return if links.nil?
        site = @context.registers[:site]
        target_linked_docs = []
        links.each do |l|
          doc = site.documents.select{ |d| d.url == l['doc_url'] && d.type.to_s == doc_type.to_s }
          if doc.nil? || doc.size != 1
            links.delete(l)
          end
        end
        return links.uniq
      end

      # usage: {% assign author_links = page.links | link_type = "author" %}
      # "link_type" is the wikilink's type, the string that appears before the link in `link-type::[[wikilink]]`.
      def link_type(links, link_type)
        return if links.nil?
        site = @context.registers[:site]
        target_linked_docs = []
        link.each do |l|
          if l['type'].to_s == link_type.to_s
            docs = site.documents.select{ |d| d.url == l['doc_url'] }
            if !docs.nil? && docs.size == 1
              links.delete(l)
            end
          end
        end
        return target_linked_docs.uniq
      end

    end

  end
end
