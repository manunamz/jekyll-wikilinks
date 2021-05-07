# frozen_string_literal: true
require "jekyll"
require_relative "jekyll-wikilinks/version"

# can't use converters because it does not have access to jekyll's 'site' 
# object -- which we need to build a element's href attribute.
class JekyllWikilinks < Jekyll::Generator

	def generate(site)
		wikilinks_collection = site.config["wikilinks_collection"]
		all_notes = site.collections[wikilinks_collection].docs
		all_pages = site.pages
		all_docs = all_notes + all_pages
		link_extension = !!site.config["use_html_extension"] ? '.html' : ''

		all_docs.each do |cur_note|
		parse_wiki_links(site, all_docs, cur_note, link_extension)
		end
	end

	def parse_wiki_links(site, all_notes, note, link_extension)
	  # some regex taken from vscode-markdown-notes: https://github.com/kortina/vscode-markdown-notes/blob/master/syntaxes/notes.tmLanguage.json   
	  # Convert all Wiki/Roam-style double-bracket link syntax to plain HTML
	  # anchor tag elements (<a>) with "internal-link" CSS class
	  all_notes.each do |note_potentially_linked_to|
	    namespace_from_filename = File.basename(
	      note_potentially_linked_to.basename,
	      File.extname(note_potentially_linked_to.basename)
	    )

	    # regex: extract note name from the end of the string to the first occurring '.'
	    # ex: 'garden.lifecycle.bamboo-shoot' -> 'bamboo shoot'
	    name_from_namespace = namespace_from_filename.match('([^.]*$)')[0].gsub('-', ' ')
	    # Replace double-bracketed links using note filename
	    # [[feline.cats]]
	    # ⬜️ vscode-markdown-notes version: (\[\[)([^\|\]]+)(\]\])
	    note.content = note.content.gsub(
	      /\[\[#{namespace_from_filename}\]\]/i,
	      "<a class='wiki-link' href='#{site.baseurl}#{note_potentially_linked_to.data['permalink']}#{link_extension}'>#{name_from_namespace}</a>"
	    )

	    # Replace double-bracketed links with alias (right) using note title
	    # [[feline.cats|this is a link to the note about cats]]
	    # ✅ vscode-markdown-notes version: (\[\[)([^\]\|]+)(\|)([^\]]+)(\]\])
	    note.content = note.content.gsub(
	      /(\[\[)(#{namespace_from_filename})(\|)([^\]]+)(\]\])/i,
	      "<a class='wiki-link' href='#{site.baseurl}#{note_potentially_linked_to.data['permalink']}#{link_extension}'>\\4</a>"
	    )

	    # Replace double-bracketed links with alias (left) using note title
	    # [[this is a link to the note about cats|feline.cats]]
	    # ✅ vscode-markdown-notes version: (\[\[)([^\]\|]+)(\|)([^\]]+)(\]\])
	    note.content = note.content.gsub(
	      /(\[\[)([^\]\|]+)(\|)(#{namespace_from_filename})(\]\])/i,
	      "<a class='wiki-link' href='#{site.baseurl}#{note_potentially_linked_to.data['permalink']}#{link_extension}'>\\2</a>"
	    )
	  end

	  # At this point, all remaining double-bracket-wrapped words are
	  # pointing to non-existing pages, so let's turn them into disabled
	  # links by greying them out and changing the cursor
	  note.content = note.content.gsub(
	    /\[\[(.*)\]\]/i, # match on the remaining double-bracket links
	    <<~HTML.chomp    # replace with this HTML (\\1 is what was inside the brackets)
	      <span title='There is no note that matches this link.' class='invalid-wiki-link'>[[\\1]]</span>
	    HTML
	  )
	end
end
