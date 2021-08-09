# frozen_string_literal: true

module Jekyll
  module WikiLinks

    module TypeFilters
      # 'links' accepts both untyped links, typed links, and attributes; fore and back.

      # usage: {% assign note_links = page.links | doc_type = "notes" %}
      # "doc_type" is the jekyll type ("pages", "posts", "<collection-name>")
      def doc_type(links, doc_type)
        return if links.nil?
        target_links = []
        links.each do |l|
          target_links << l if l['doc'].type.to_str == doc_type.to_str
        end
        return target_links.uniq
      end

      # usage: {% assign author_links = page.links | link_type = "author" %}
      # "link_type" is the wikilink's type, the string that appears before the link in `link-type::[[wikilink]]`.
      def link_type(links, link_type)
        return if links.nil?
        target_links = []
        link.each do |l|
          target_links << l if l['type'].to_str == link_type.to_str
        end
        return target_links.uniq
      end

    end
    
  end
end
