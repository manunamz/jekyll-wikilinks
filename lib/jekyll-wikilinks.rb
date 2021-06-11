# frozen_string_literal: true
require "jekyll"
require_relative "jekyll-wikilinks/context"
require_relative "jekyll-wikilinks/filter"
require_relative "jekyll-wikilinks/version"

module JekyllWikiLinks
	class Generator < Jekyll::Generator
		attr_accessor :site, :config, :md_docs, :graph_nodes, :graph_links

		# Use Jekyll's native relative_url filter
		include Jekyll::Filters::URLFilters

		CONFIG_KEY = "wikilinks"
		CONVERTER_CLASS = Jekyll::Converters::Markdown
		ENABLED_KEY = "enabled"
		ENABLED_GRAPH_DATA_KEY = "enabled"
		EXCLUDE_KEY = "exclude"
		EXCLUDE_GRAPH_KEY = "exclude"
		GRAPH_DATA_KEY = "d3_graph_data"

		def initialize(config)
			@config = config
		end

		def generate(site)
			return if disabled?
			Jekyll.logger.debug "Excluded jekyll types: ", option(EXCLUDE_KEY)
			Jekyll.logger.debug "Excluded jekyll types in graph: ", option_graph(EXCLUDE_GRAPH_KEY)

			@site = site    
			@context = context

			documents = []
			documents += site.pages if !exclude?(:pages)
			included_docs = site.docs_to_write.filter { |d| !exclude?(d.type) }
			documents += included_docs
			@md_docs = documents.select {|doc| markdown_extension?(doc.extname) }

			old_config_warn()

			# build links
			md_docs.each do |document|
				parse_wiki_links(document)
			end

			# backlinks data handling
			@graph_nodes, @graph_links = [], []
			md_docs.each do |document|
				document.data['backlinks'] = get_backlinks(document)
				if !disabled_graph_data? && !exclude_graph?(document.type)
					generate_graph_data(document) 
				end
			end

			if !disabled_graph_data?
				write_graph_data()
			end
		end

		def old_config_warn()
			if config.include?("wikilinks_collection")
				Jekyll.logger.warn "Deprecated: As of 0.0.3, 'wikilinks_collection' is no longer used for configs. jekyll-wikilinks will scan all markdown files by default. Check README for details: https://manunamz.github.io/jekyll-wikilinks/"
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
				
				render_txt = note_potentially_linked_to.data['title'].downcase
				note_url = relative_url(note_potentially_linked_to.url) if note_potentially_linked_to&.url

				# 
				# links
				# 

				# Replace double-bracketed links using note title
				# [[feline.cats]]
				regex_wl, cap_gr = regex_wiki_link(title_from_filename)
				note.content.gsub!(
					regex_wl,
					"<a class='wiki-link' href='#{note_url}'>#{render_txt}</a>"
				)

				# Replace double-bracketed links with alias (right)
				# [[feline.cats|this is a link to the note about cats]]
				regex_wl, cap_gr = regex_wiki_link_w_alias_right(title_from_filename)
				note.content.gsub!(
					regex_wl,
					"<a class='wiki-link' href='#{note_url}'>#{cap_gr}</a>"
				)

				# Replace double-bracketed links with alias (left)
				# [[this is a link to the note about cats|feline.cats]]
				regex_wl, cap_gr = regex_wiki_link_w_alias_left(title_from_filename)
				note.content.gsub!(
					regex_wl,
					"<a class='wiki-link' href='#{note_url}'>#{cap_gr}</a>"
				)

				# 
				# fragments/anchors
				# 

				# Replace double-bracketed header links using note title and header
				# [[feline.cats#meow]] -> "cats > meow"
				matches = note.content.scan(/\[\[(#{title_from_filename})#(.+?)\]\]/i)
				matches.each do |m|
					wiki_link_text = m[0]
					fragment_text = m[1]
					downcased_fragment_text = fragment_text.downcase
					if has_header?(fragment_text, note_potentially_linked_to)
						note.content.gsub!(
							/\[\[(#{wiki_link_text})#(#{fragment_text})\]\]/i,
							"<a class='wiki-link' href='#{note_url}\##{downcased_fragment_text}'>#{render_txt} > #{fragment_text}</a>"
						)
					end
				end

				# Replace double-bracketed header links with alias (right)
				# [[feline.cats#meow|this is a link to the note about cats]]
				matches = note.content.scan(/(\[\[)(#{title_from_filename})#(.+?)(\|)([^\]]+)(\]\])/i)
				matches.each do |m|
					# wiki_link_text = m[1] (which == title_from_filename)
					fragment_text = m[2]
					aliased_text = m[4]
					downcased_fragment_text = fragment_text.downcase
					if has_header?(fragment_text, note_potentially_linked_to)
						note.content.gsub!(
							/(\[\[)(#{title_from_filename})#(#{fragment_text})(\|)([^\]]+)(\]\])/i,
							"<a class='wiki-link' href='#{note_url}\##{downcased_fragment_text}'>#{aliased_text}</a>"
						)
					end
				end

				# Replace double-bracketed header links with alias (left)
				# [[this is a link to the note about cats|feline.cats#meow]]
				matches = note.content.scan(/(\[\[)([^\]\|]+)(\|)(#{title_from_filename})#(.+?)(\]\])/i)
				matches.each do |m|
					aliased_text = m[1]
					# wiki_link_text = m[3] (which == title_from_filename)
					fragment_text = m[4]
					downcased_fragment_text = fragment_text.downcase
					if has_header?(fragment_text, note_potentially_linked_to)
						note.content.gsub!(
							/(\[\[)([^\]\|]+)(\|)(#{title_from_filename})#(#{fragment_text})(\]\])/i,
							"<a class='wiki-link' href='#{note_url}\##{downcased_fragment_text}'>#{aliased_text}</a>"
						)
					end
				end

				# Replace double-bracketed block links using note title and block id
				# [[feline.cats#^id]] -> "cats > ^id"

			end

			# At this point, all remaining double-bracket-wrapped words are
			# pointing to non-existing pages, so let's disable them
			regex_wl, cap_gr = regex_wiki_link()
			note.content.gsub!(
				regex_wl,
				"<span title=\"Content not found.\" class=\"invalid-wiki-link\">[[#{cap_gr}]]</span>"
			)
		end

		def get_backlinks(doc)
			backlinks = []
			md_docs.each do |backlinked_doc|
				if backlinked_doc.content.include?(doc.url)
					backlinks << backlinked_doc
				end
			end
			return backlinks
		end

		def has_header?(header, note)
			# note: leading + trailing whitespace is ignored when matching headers
			regex_header, _ = regex_header()
			regex_setext_header, _ = regex_setext_header()
			header_results = note.content.scan(regex_header).flatten.map { |r| r.strip } 
			setext_header_results = note.content.scan(regex_setext_header).flatten.map { |r| r.strip } 
			return header_results.include?(header.strip) || setext_header_results.include?(header.strip)
		end

		def invalid_wiki_links(doc)
			regex, _ = regex_invalid_wiki_link()
			return doc.content.scan(regex)[0]
		end

		def generate_graph_data(doc)
			Jekyll.logger.debug "Processing graph nodes for doc: ", doc.data['title']
			# missing nodes
			missing_node_names = invalid_wiki_links(doc)
			if !missing_node_names.nil?
				missing_node_names.each do |missing_node_name| 
					if graph_nodes.none? { |node| node[:id] == missing_node_name }
						Jekyll.logger.warn "Net-Web node missing: ", missing_node_name
						Jekyll.logger.warn " in: ", doc.data['slug']  
						graph_nodes << {
							id: missing_node_name,
							url: '',
							label: missing_node_name,
						}
					end
					graph_links << {
						source: relative_url(doc.url),
						target: missing_node_name,
					}
				end
			end
			# existing nodes
			graph_nodes << {
				id: relative_url(doc.url),
				url: relative_url(doc.url),
				label: doc.data['title'],
			}
			get_backlinks(doc).each do |b|
				if !exclude_graph?(b.type)
					graph_links << {
						source: relative_url(b.url),
						target: relative_url(doc.url),
					}
				end
			end
		end

		def write_graph_data()
			# from: https://github.com/jekyll/jekyll/issues/7195#issuecomment-415696200
			static_file = Jekyll::StaticFile.new(site, site.source, "/assets", "graph-net-web.json")
			File.write(@site.source + static_file.relative_path, JSON.dump({
				links: graph_links,
				nodes: graph_nodes,
			}))
		end

		def context
			@context ||= JekyllWikiLinks::Context.new(site)
		end


		def exclude?(type)
			return false unless option(EXCLUDE_KEY)
			return option(EXCLUDE_KEY).include?(type.to_s)
		end

		def exclude_graph?(type)
			return false unless option_graph(EXCLUDE_KEY)
			return option_graph(EXCLUDE_KEY).include?(type.to_s)
		end

		def markdown_extension?(extension)
			markdown_converter.matches(extension)
		end

		def markdown_converter
			@markdown_converter ||= site.find_converter_instance(CONVERTER_CLASS)
		end

		def option(key)
			config[CONFIG_KEY] && config[CONFIG_KEY][key]
		end

		def option_graph(key)
			config[GRAPH_DATA_KEY] && config[GRAPH_DATA_KEY][key]
		end

		def disabled?
			option(ENABLED_KEY) == false
		end

		def disabled_graph_data?
			option_graph(ENABLED_GRAPH_DATA_KEY) == false
		end

		# regex
		# returns two items: regex and a target capture group (text to be rendered)
		# using functions instead of constants because of the need to access 'wiki_link_text'
		#   -- esp. when aliasing.

		def regex_header()
			regex = /^#+(.*)$/i
			cap_gr = "\\1"
			return regex, cap_gr
		end

		def regex_setext_header()
			regex = /^ {0,3}(.*)\n[-=]{2}+[ \t\r\f\v]*/i
			cap_gr = "\\1"
			return regex, cap_gr
		end

		def regex_invalid_wiki_link()
			# identify missing links in note via .invalid-wiki-link class and nested note-name.
			regex = /invalid-wiki-link[^\]]+\[\[([^\]]+)\]\]/i
			cap_gr = "\\1" # this is mostly just to remain consistent with other regex functions
			return regex, cap_gr
		end

		def regex_wiki_link(wiki_link_text='')
			# includes fragments
			if wiki_link_text.empty?
				regex = /(\[\[)([^\]]+)(\]\])/i
				cap_gr = "\\2" 
				return regex, cap_gr
			else 
				regex = /(\[\[)(#{wiki_link_text})(\]\])/i
				return regex, wiki_link_text
			end
		end

		def regex_wiki_link_w_alias()
			# includes fragments
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