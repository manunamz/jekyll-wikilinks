# frozen_string_literal: true

module Jekyll
  module WikiLinks

    module TypeFilters
      # 'links' accepts untyped links, typed links, and attributes; fore and back.

      # usage: {% assign note_links = page.links | doc_type = "notes" %}
      # TODO: if you simply filter links against specific jekyll types, this filter is completely unecessary...
      #       // looping through backlinks:
      #       {% assign note_links = site.notes | where: "url", backlink.url | first %}
      def doc_type(links, doc_type)
        Jekyll.logger.error("'links' should not be nil") if links.nil?
        return "No doc type given" if doc_type.empty?
        return [] if links.empty?

        site = @context.registers[:site]
        links.each do |l|
          # links
          if l.keys.include?('url')
            doc = site.documents.select{ |d| d.url == l['url'] && d.type.to_s == doc_type.to_s }
            if !doc.nil? && doc.size != 1
              links.delete(l)
            end
          # attributes
          elsif l.keys.include?('urls')
            l['urls'].each do |lurl|
              doc = site.documents.select{ |d| d.url == lurl && d.type.to_s == doc_type.to_s }
              if !doc.nil? && doc.size != 1
                links['urls'].delete(lurl)
              end
            end
          else
            Jekyll.logge.error("In 'doc_type' filter, 'links' do not have 'url' or 'urls'")
          end
        end
        return links.uniq
      end

      # usage: {% assign author_links = page.links | rel_type = "author" %}
      def rel_type(links, link_type)
        Jekyll.logger.error("'links' should not be nil") if links.nil?
        return "No link type given" if link_type.empty?
        return [] if links.empty?

        site = @context.registers[:site]
        links.each do |l|
          if l.keys.include?('url')
            if l['type'].to_s == link_type.to_s
              docs = site.documents.select{ |d| d.url == l['url'] }
              if !doc.nil? && doc.size != 1
                links.delete(l)
              end
            end
          elsif l.keys.include?('urls')
            l['urls'].each do |lurl|
              docs = site.documents.select{ |d| d.url == lurl }
              if !doc.nil? && doc.size != 1
                links['urls'].delete(lurl)
              end
            end
          else
            Jekyll.logge.error("In 'rel_type' filter, 'links' do not have 'url' or 'urls'")
          end
        end
        return links.uniq
      end

    end

  end
end
