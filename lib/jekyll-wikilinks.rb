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

			# build links
			md_docs.each do |document|
				parse_wiki_links(document)
			end

			# extract link graph/metadata
			graph_nodes, graph_links = [], []
			md_docs.each do |document|
				document.data['backlinks'] = add_backlinks_json(site.baseurl, '', md_docs, document, graph_nodes, graph_links)
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
				title_from_filename = File.basename(
					note_potentially_linked_to.basename,
					File.extname(note_potentially_linked_to.basename)
				)
				
				note_url = relative_url(note_potentially_linked_to.url) if note_potentially_linked_to&.url

				# Replace double-bracketed links using note title
				# [[feline.cats]]
				regex_wl, cap_gr = regex_wiki_link(title_from_filename)
				render_txt = note_potentially_linked_to.data['title'].downcase
				note.content = note.content.gsub(
					regex_wl,
					"<a class='wiki-link' href='#{note_url}'>#{render_txt}</a>"
				)

				# Replace double-bracketed links with alias (right)
				# [[feline.cats|this is a link to the note about cats]]
				regex_wl, cap_gr = regex_wiki_link_w_alias_right(title_from_filename)
				note.content = note.content.gsub(
					regex_wl,
					"<a class='wiki-link' href='#{note_url}'>#{cap_gr}</a>"
				)

				# Replace double-bracketed links with alias (left)
				# [[this is a link to the note about cats|feline.cats]]
				regex_wl, cap_gr = regex_wiki_link_w_alias_left(title_from_filename)
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

		def add_backlinks_json(baseurl, link_extension, all_notes, note, graph_nodes, graph_links)
			# net-web: Identify note backlinks and add them to each note
			backlinks = []
			all_notes.each do |backlinked_note|
				if backlinked_note.content.include?(note.url)
					backlinks << backlinked_note
				end
			end
			# identify missing links in note via .invalid-wiki-link class and nested note-name.
			missing_node_names = note.content.scan(/invalid-wiki-link[^\]]+\[\[([^\]]+)\]\]/i)
			if !missing_node_names.nil?
				missing_node_names.each do |missing_no_name_in_array| 
					missing_no_namespace = missing_no_name_in_array[0]
					# add missing nodes
					if graph_nodes.none? { |node| node[:id] == missing_no_namespace }
						Jekyll.logger.warn "Net-Web node missing: ", missing_no_namespace
						Jekyll.logger.warn " in: ", note.data['slug']  
						graph_nodes << {
							id: missing_no_namespace,
							url: '',
							label: missing_no_namespace,
						}
					end
					# add missing links
					graph_links << {
						source: note.data['id'],
						target: missing_no_namespace,
					}
				end
			end
			# graph
			graph_nodes << {
				id: note.data['id'],
				url: "#{baseurl}#{note.url}#{link_extension}", # relative_url(note.url) if note&.url
				label: note.data['title'],
			}
			backlinks.each do |b|
				graph_links << {
					source: b.data['id'],
					target: note.data['id'],
				}
			end
			return backlinks
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