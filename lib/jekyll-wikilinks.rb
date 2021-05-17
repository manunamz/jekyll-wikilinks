# frozen_string_literal: true
require "jekyll"
require_relative "jekyll-wikilinks/context"
require_relative "jekyll-wikilinks/version"


# refs:
# 	- github wiki: https://docs.github.com/en/communities/documenting-your-project-with-wikis/editing-wiki-content
# 	- use ruby classes more fully: https://github.com/benbalter/jekyll-relative-links
#   - backlinks generator: https://github.com/maximevaillancourt/digital-garden-jekyll-template
#   - regex: https://github.com/kortina/vscode-markdown-notes/blob/0ac9205ea909511b708d45cbca39c880688b5969/syntaxes/notes.tmLanguage.json
#   - converterible example: https://github.com/metala/jekyll-wikilinks-plugin/blob/master/wikilinks.rb 
module JekyllWikiLinks
	class Generator < Jekyll::Generator
		attr_accessor :site, :md_docs

	  # Use Jekyll's native relative_url filter
	  include Jekyll::Filters::URLFilters

		CONVERTER_CLASS = Jekyll::Converters::Markdown

		def generate(site)
			@site = site		
			@context = context
			documents = site.pages + site.docs_to_write
			@md_docs = documents.select {|doc| markdown_extension?(doc.extname) } # if collections?

			old_config_warn()

			md_docs.each do |document|
				parse_wiki_links(document)
			end
		end

		def old_config_warn()
			if site.config.include?("wikilinks_collection")
				Jekyll.logger.warn "Deprecated: As of 0.0.3, 'wikilinks_collection' is no longer used for configs. jekyll-wikilinks will scan all markdown files by default. Check README for details: https://shorty25h0r7.github.io/jekyll-wikilinks/"
			end
		end

		def parse_wiki_links(note)
		  # Convert all Wiki/Roam-style double-bracket link syntax to plain HTML
		  # anchor tag elements (<a>) with "wiki-link" CSS class
		  md_docs.each do |note_potentially_linked_to|
		    namespace_from_filename = File.basename(
		      note_potentially_linked_to.basename,
		      File.extname(note_potentially_linked_to.basename)
		    )
		    
		    note_url = relative_url(note_potentially_linked_to.url) if note_potentially_linked_to&.url

		    # Replace double-bracketed links using note title
		    # [[feline.cats]]
		    regex_wl, cap_gr = regex_wiki_link(namespace_from_filename)
		    note.content = note.content.gsub(
		      regex_wl,
		      "<a class='wiki-link' href='#{note_url}'>#{note_potentially_linked_to.title.downcase}</a>"
		    )

		    # Replace double-bracketed links with alias (right)
		    # [[feline.cats|this is a link to the note about cats]]
		    regex_wl, cap_gr = regex_wiki_link_w_alias_right(namespace_from_filename)
		    note.content = note.content.gsub(
		      regex_wl,
		      "<a class='wiki-link' href='#{note_url}'>#{cap_gr}</a>"
		    )

		    # Replace double-bracketed links with alias (left)
		    # [[this is a link to the note about cats|feline.cats]]
		    regex_wl, cap_gr = regex_wiki_link_w_alias_left(namespace_from_filename)
		    note.content = note.content.gsub(
		      regex_wl,
		      "<a class='wiki-link' href='#{note_url}'>#{cap_gr}</a>"
		    )
		  end

		  # At this point, all remaining double-bracket-wrapped words are
		  # pointing to non-existing pages, so let's turn them into disabled
		  # links by greying them out and changing the cursor
		  # vanilla wiki-links
		  regex_wl, cap_gr = regex_wiki_link()
		  note.content = note.content.gsub(
		    regex_wl,
		    "<span title='There is no note that matches this link.' class='invalid-wiki-link'>[[#{cap_gr}]]</span>"
		  )
		  # aliases -- both kinds
		  regex_wl, cap_gr = regex_wiki_link_w_alias()		  
		  note.content = note.content.gsub(
		    regex_wl,
		    "<span title='There is no note that matches this link.' class='invalid-wiki-link'>[[#{cap_gr}]]</span>"
		  )
		end

	  def context
	    @context ||= JekyllWikiLinks::Context.new(site)
	  end

		def markdown_extension?(extension)
			markdown_converter.matches(extension)
		end

		def markdown_converter
			@markdown_converter ||= site.find_converter_instance(CONVERTER_CLASS)
		end

		# regex
		# returns two items: regex and a target capture group (text to be rendered)
		# using functions instead of constants because of the need to access 'wiki_link_text'
		#   -- esp. when aliasing.

		def regex_wiki_link(wiki_link_text='')
			if wiki_link_text.empty?
				regex = /(\[\[)([^\|\]]+)(\]\])/i
				cap_gr = "\\2" 
				return regex, cap_gr
			else 
				regex = /\[\[#{wiki_link_text}\]\]/i
				cap_gr = wiki_link_text
				return regex, cap_gr
			end
		end

		def regex_wiki_link_w_alias()
			regex = /(\[\[)([^\]\|]+)(\|)([^\]]+)(\]\])/i
			cap_gr = "\\2|\\4"
			return regex, cap_gr 
		end

		def regex_wiki_link_w_alias_left(wiki_link_text)
			raise ArgumentError.new(
		    "Expected a value for 'wiki_link_text'"
		  ) if wiki_link_text.nil?
		  regex = /(\[\[)([^\]\|]+)(\|)(#{wiki_link_text})(\]\])/i
		  cap_gr = "\\2"
			return regex, cap_gr
		end

		def regex_wiki_link_w_alias_right(wiki_link_text)
			raise ArgumentError.new(
		    "Expected a value for 'wiki_link_text'"
		  ) if wiki_link_text.nil?
		  regex = /(\[\[)(#{wiki_link_text})(\|)([^\]]+)(\]\])/i
		  cap_gr = "\\4"
			return regex, cap_gr
		end

	end
end