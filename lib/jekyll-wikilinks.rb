# frozen_string_literal: true
require "jekyll"
require_relative "jekyll-wikilinks/context"
require_relative "jekyll-wikilinks/filter"
require_relative "jekyll-wikilinks/regex"
require_relative "jekyll-wikilinks/version"
require_relative "jekyll-wikilinks/wikilink"

module JekyllWikiLinks
	class Generator < Jekyll::Generator
		attr_accessor :site, :config, :md_docs, :graph_nodes, :graph_links

		# Use Jekyll's native relative_url filter
		include Jekyll::Filters::URLFilters

		CONVERTER_CLASS = Jekyll::Converters::Markdown
		# config
		CONFIG_KEY = "wikilinks"
		ENABLED_KEY = "enabled"
		EXCLUDE_KEY = "exclude"
		# graph config
		GRAPH_DATA_KEY = "d3_graph_data"
		ENABLED_GRAPH_DATA_KEY = "enabled"
		EXCLUDE_GRAPH_KEY = "exclude"

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
				if !disabled_graph_data? && !excluded_in_graph?(document.type)
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
		
		def parse_wiki_links(doc)
			wikilink_matches = doc.content.scan(REGEX_WIKI_LINKS)
			return unless !wikilink_matches.nil? && wikilink_matches.size != 0
			# recursive embed with max level; insert markdown
			# scan match again
			wikilink_matches.each do |wl_match|
				wikilink = WikiLink.new(
					wl_match[0],
					wl_match[1],
				  wl_match[2],
					wl_match[3],
					wl_match[4],
					wl_match[5],
				)
				doc.content.sub!(
					wikilink.md_link_regex,
					build_html_link(wikilink)
				)
			end
		end

		def build_html_link(wikilink)
			# TODO link_type
			linked_doc = get_linked_doc(wikilink.filename)
			if !linked_doc.nil?
				lnk_doc_rel_url = relative_url(linked_doc.url) if linked_doc&.url
				# alias
				wikilink_inner_txt = wikilink.clean_alias_txt if wikilink.aliased?
				# TODO not sure about downcase
				fname_inner_txt = linked_doc['title'].downcase if wikilink_inner_txt.nil?
				link_lvl = wikilink.describe['level']

				if (link_lvl == "file" && !linked_doc.nil?)
					wikilink_inner_txt = "#{fname_inner_txt}" if wikilink_inner_txt.nil?
					return "<a class='wiki-link' href='#{lnk_doc_rel_url}'>#{wikilink_inner_txt}</a>"
				
				elsif ("header" && !linked_doc.nil? && doc_has_header?(wikilink.header_txt, linked_doc))
					wikilink_inner_txt = "#{fname_inner_txt} > #{wikilink.header_txt}" if wikilink_inner_txt.nil?
					url_fragment = wikilink.header_txt.downcase
					return "<a class='wiki-link' href='#{lnk_doc_rel_url}\##{url_fragment}'>#{wikilink_inner_txt}</a>"
				
				elsif ("block" && !linked_doc.nil? && doc_has_block?(wikilink.block_id, linked_doc))
					wikilink_inner_txt = "#{fname_inner_txt} > ^#{wikilink.block_id}" if wikilink_inner_txt.nil?
					url_fragment = wikilink.block_id.downcase
					return "<a class='wiki-link' href='#{lnk_doc_rel_url}\##{url_fragment}}'>#{wikilink_inner_txt}</a>"
				
				else
					return "<span title=\"Content not found.\" class=\"invalid-wiki-link\">#{wikilink.md_link_str}</span>"
				end

			else
				return "<span title=\"Content not found.\" class=\"invalid-wiki-link\">#{wikilink.md_link_str}</span>"
			end
		end

		# doc-link validation

		def get_linked_doc(filename)
			docs = @md_docs.select{ |d| File.basename(d.basename, File.extname(d.basename)) == filename }
			return nil if docs.nil? || docs.size > 1
			return docs[0]
		end

		def doc_has_header?(header, doc)
			return if header.nil?
			# doc: leading + trailing whitespace is ignored when matching headers
			header_results = doc.content.scan(REGEX_ATX_HEADER).flatten.map { |r| r.strip } 
			setext_header_results = doc.content.scan(REGEX_SETEXT_HEADER).flatten.map { |r| r.strip } 
			return header_results.include?(header.strip) || setext_header_results.include?(header.strip)
		end

		def doc_has_block?(block_id, doc)
			#TODO
		end

		# helpers

		def get_backlinks(doc)
			backlinks = []
			@md_docs.each do |backlinked_doc|
				if backlinked_doc.content.include?(doc.url)
					backlinks << backlinked_doc
				end
			end
			return backlinks
		end

		def context
			@context ||= JekyllWikiLinks::Context.new(site)
		end

		# config helpers

		def exclude?(type)
			return false unless option(EXCLUDE_KEY)
			return option(EXCLUDE_KEY).include?(type.to_s)
		end

		def excluded_in_graph?(type)
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

		# graph

		def generate_graph_data(doc)
			Jekyll.logger.debug "Processing graph nodes for doc: ", doc.data['title']
			# missing nodes
			missing_node_names = doc.content.scan(REGEX_INVALID_WIKI_LINK)
			if !missing_node_names.nil?
				missing_node_names.each do |missing_node_name_captures| 
					missing_node_name = missing_node_name_captures[0]
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
				if !excluded_in_graph?(b.type)
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

	end
end