# frozen_string_literal: true
require "jekyll"
require_relative "context"
require_relative "doc_manager"
require_relative "filter"
require_relative "parser"

module JekyllWikiLinks
	class Generator < Jekyll::Generator
		attr_accessor :site, :config, :md_docs, :doc_manager, :graph_nodes, :graph_links

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
    REGEX_LINK_TYPE = /<a\sclass="wiki-link(\slink-type\s(?<link-type>([^"]+)))?"\shref="(?<link-url>([^"]+))">/i

		def initialize(config)
			@config = config
		end

		def generate(site)
			return if disabled?
      self.old_config_warn()
      
			Jekyll.logger.debug "Excluded jekyll types: ", option(EXCLUDE_KEY)
			Jekyll.logger.debug "Excluded jekyll types in graph: ", option_graph(EXCLUDE_GRAPH_KEY)

			@site = site    
			@context ||= JekyllWikiLinks::Context.new(site)

			docs = []
			docs += site.pages if !exclude?(:pages)
			included_docs = site.docs_to_write.filter { |d| !exclude?(d.type) }
			docs += included_docs
			@md_docs = docs.select {|doc| markdown_extension?(doc.extname) }

      @doc_manager = DocManager.new(@md_docs, @site.static_files)
      @parser = Parser.new(@context, @markdown_converter, doc_manager)

      # self.parse_wiki_links()
      @md_docs.each do |doc|
        @parser.parse(doc.content)
        self.populate_attributes(doc, @parser.typed_link_blocks)
      end
      self.populate_backlinks()

			@graph_nodes, @graph_links = [], []
			@md_docs.each do |doc|
				if !disabled_graph_data? && !self.excluded_in_graph?(doc.type)
					self.generate_graph_data(doc) 
				end
			end
			if !disabled_graph_data?
				self.write_graph_data()
			end
		end

		# helpers

    def populate_attributes(doc, typed_link_blocks)
      attributes = {}
      typed_link_blocks.each do |tl|
        attributes[tl.link_type] = @doc_manager.get_doc(tl.filename)
      end
      doc.data['attributes'] = attributes
    end

    def populate_backlinks()
      # for each document...
      @md_docs.each do |doc|
        backlinks = []
        link_types = []
        # ...process its backlinks and link_types
        @md_docs.each do |doc_to_backlink|
          match_results = doc_to_backlink.content.scan(REGEX_LINK_TYPE)
          match_results.each do |m|
            if m[1] == doc.url
              backlinks << doc_to_backlink
              link_types << m[0]
            end
          end
        end
        doc.data['backlinks'] = backlinks
        doc.data['link_types'] = link_types
      end
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
			doc.data['backlinks'].each do |b|
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