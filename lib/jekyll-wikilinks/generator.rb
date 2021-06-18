# frozen_string_literal: true
require "jekyll"
require_relative "context"
require_relative "filter"
require_relative "parser"
require_relative "validator"

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

    # REGEX_NOT_GREEDY dependent on parser
    # identify missing links in doc via .invalid-wiki-link class and nested doc-text.
    REGEX_INVALID_WIKI_LINK = /invalid-wiki-link#{REGEX_NOT_GREEDY}\[\[(#{REGEX_NOT_GREEDY})\]\]/i

		def initialize(config)
			@config = config
		end

		def generate(site)
			return if disabled?
			Jekyll.logger.debug "Excluded jekyll types: ", option(EXCLUDE_KEY)
			Jekyll.logger.debug "Excluded jekyll types in graph: ", option_graph(EXCLUDE_GRAPH_KEY)

			@site = site    
			@context = context

			docs = []
			docs += site.pages if !exclude?(:pages)
			included_docs = site.docs_to_write.filter { |d| !exclude?(d.type) }
			docs += included_docs
			@md_docs = docs.select {|doc| markdown_extension?(doc.extname) }

			old_config_warn()
      parse_wiki_links()

			# backlinks data handling
			@graph_nodes, @graph_links = [], []
			md_docs.each do |doc|
				doc.data['backlinks'] = get_backlinks(doc)
				if !disabled_graph_data? && !excluded_in_graph?(doc.type)
					generate_graph_data(doc) 
				end
			end
			if !disabled_graph_data?
				write_graph_data()
			end
		end
		
    # TODO: proper parse tree; move parsing and html building to parser.rb

		def parse_wiki_links()
      md_docs.each do |doc|
        wikilink_objs = Parser.new(doc).wikilinks
        next if wikilink_objs.nil? 
        wikilink_objs.each do |wikilink|
          doc.content.sub!(
            wikilink.md_link_regex,
            build_html_link(wikilink)
          )
        end
      end
		end

    # build html

    def build_html_embed(title, content, url)
      # multi-line for readability
      return [
        "<div class=\"wiki-link-embed\">",
          "<div class=\"wiki-link-embed-title\">",
            "#{title}",
          "</div>",
          "<div class=\"wiki-link-embed-content\">",
            "#{@markdown_converter.convert(content)}",
          "</div>",
          "<div class=\"wiki-link-embed-link\">",
            "<a href=\"#{url}\"></a>",
          "</div>",
        "</div>",
      ].join("\n").gsub!("\n", "")
    end

    def build_html_img_embed(img_file)
      "<p><span class=\"wiki-link-embed-image\"><img class=\"wiki-link-img\" src=\"#{relative_url(img_file.relative_path)}\"/></span></p>"
    end

		def build_html_link(wikilink)
      if wikilink.is_img?
			  linked_doc = Validator.get_linked_image(@site.static_files, wikilink.filename)
        if wikilink.embedded? && wikilink.is_img?
          return build_html_img_embed(linked_doc)
        end
      end
      linked_doc = Validator.get_linked_doc(@md_docs, wikilink.filename)
			if !linked_doc.nil?
				# TODO link_type

				# label
				wikilink_inner_txt = wikilink.clean_label_txt if wikilink.labelled?

				lnk_doc_rel_url = relative_url(linked_doc.url) if linked_doc&.url
        # TODO not sure about downcase
				fname_inner_txt = linked_doc['title'].downcase if wikilink_inner_txt.nil?
				
        link_lvl = wikilink.describe['level']
				if (link_lvl == "file")
					wikilink_inner_txt = "#{fname_inner_txt}" if wikilink_inner_txt.nil?
          return build_html_embed(
            linked_doc['title'],
            get_doc_content(wikilink.filename),
            lnk_doc_rel_url
          ) if wikilink.embedded?
				elsif (link_lvl == "header" && Validator.doc_has_header?(linked_doc, wikilink.header_txt))
					lnk_doc_rel_url += "\#" + wikilink.header_txt.downcase
					wikilink_inner_txt = "#{fname_inner_txt} > #{wikilink.header_txt}" if wikilink_inner_txt.nil?
				elsif (link_lvl == "block" && Validator.doc_has_block_id?(linked_doc, wikilink.block_id))
					lnk_doc_rel_url += "\#" + wikilink.block_id.downcase
					wikilink_inner_txt = "#{fname_inner_txt} > ^#{wikilink.block_id}" if wikilink_inner_txt.nil?
				else
					return "<span title=\"Content not found.\" class=\"invalid-wiki-link\">#{wikilink.md_link_str}</span>"
				end
				return "<a class='wiki-link' href='#{lnk_doc_rel_url}'>#{wikilink_inner_txt}</a>"
			else
				return "<span title=\"Content not found.\" class=\"invalid-wiki-link\">#{wikilink.md_link_str}</span>"
			end
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

    def get_doc_content(filename)
      docs = md_docs.select{ |d| File.basename(d.basename, File.extname(d.basename)) == filename }
      return docs[0].content if docs.size == 1
      return nil
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

    # deprecations
    def old_config_warn()
      if config.include?("wikilinks_collection")
        Jekyll.logger.warn "As of 0.0.3, 'wikilinks_collection' is no longer used for configs. jekyll-wikilinks will scan all markdown files by default. Check README for details."
      end
    end

	end
end