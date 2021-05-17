# frozen_string_literal: true
require "jekyll"
require_relative "jekyll-wikilinks/version"

# can't use converters because it does not have access to jekyll's 'site'
# object -- which we need to build a element's href attribute.

# refs:
# 	- use ruby classes more fully: https://github.com/benbalter/jekyll-relative-links
#   - backlinks generator: https://github.com/maximevaillancourt/digital-garden-jekyll-template
#   - regex: https://github.com/kortina/vscode-markdown-notes/blob/0ac9205ea909511b708d45cbca39c880688b5969/syntaxes/notes.tmLanguage.json
#   - converterible example: https://github.com/metala/jekyll-wikilinks-plugin/blob/master/wikilinks.rb
class JekyllWikilinks < Jekyll::Generator
	attr_accessor :site, :md_docs

	CONVERTER_CLASS = Jekyll::Converters::Markdown

	def generate(site)
		@site = site		
		documents = site.pages + site.docs_to_write
		@md_docs = documents.select {|doc| markdown_extension?(doc.extname) } # if collections?
		link_extension = site.config["permalink"] != "pretty" ? '.html' : ''
		
		old_config_warn()

		md_docs.each do |document|
			parse_wiki_links(document, link_extension)
		end
	end

	def old_config_warn()
		if site.config.include?("wikilinks_collection")
			Jekyll.logger.warn "'wikilinks_collection' is no longer used for configs.\n"
		end
	end

	def parse_wiki_links(note, link_extension)
	  # some regex taken from vscode-markdown-notes: https://github.com/kortina/vscode-markdown-notes/blob/master/syntaxes/notes.tmLanguage.json   
	  # Convert all Wiki/Roam-style double-bracket link syntax to plain HTML
	  # anchor tag elements (<a>) with "internal-link" CSS class
	  md_docs.each do |note_potentially_linked_to|
	    namespace_from_filename = File.basename(
	      note_potentially_linked_to.basename,
	      File.extname(note_potentially_linked_to.basename)
	    )

	    # Replace double-bracketed links using note title
	    # [[feline.cats]]
	    note.content = note.content.gsub(
	      /\[\[#{namespace_from_filename}\]\]/i,
	      "<a class='wiki-link' href='#{site.baseurl}#{note_potentially_linked_to.data['permalink']}#{link_extension}'>#{note_potentially_linked_to.data['title'].downcase}</a>"
	    )

	    # Replace double-bracketed links with alias (right)
	    # [[feline.cats|this is a link to the note about cats]]
	    note.content = note.content.gsub(
	      /(\[\[)(#{namespace_from_filename})(\|)([^\]]+)(\]\])/i,
	      "<a class='wiki-link' href='#{site.baseurl}#{note_potentially_linked_to.data['permalink']}#{link_extension}'>\\4</a>"
	    )

	    # Replace double-bracketed links with alias (left)
	    # [[this is a link to the note about cats|feline.cats]]
	    note.content = note.content.gsub(
	      /(\[\[)([^\]\|]+)(\|)(#{namespace_from_filename})(\]\])/i,
	      "<a class='wiki-link' href='#{site.baseurl}#{note_potentially_linked_to.data['permalink']}#{link_extension}'>\\2</a>"
	    )
	  end

	  # At this point, all remaining double-bracket-wrapped words are
	  # pointing to non-existing pages, so let's turn them into disabled
	  # links by greying them out and changing the cursor
	  note.content = note.content.gsub(
	    /(\[\[)([^\|\]]+)(\]\])/i, # match on the remaining double-bracket links
	    <<~HTML.chomp    # replace with this HTML (\\2 is what was inside the brackets)
	      <span title='There is no note that matches this link.' class='invalid-wiki-link'>[[\\2]]</span>
	    HTML
	  )
	  # aliases -- both kinds
	  note.content = note.content.gsub(
	    /(\[\[)([^\]\|]+)(\|)([^\]]+)(\]\])/i,
	    <<~HTML.chomp    # replace with this HTML (\\2 is what was inside the brackets)
	      <span title='There is no note that matches this link.' class='invalid-wiki-link'>[[\\2|\\4]]</span>
	    HTML
	  )
	end

	def markdown_extension?(extension)
		markdown_converter.matches(extension)
	end

	def markdown_converter
		@markdown_converter ||= site.find_converter_instance(CONVERTER_CLASS)
	end
end
