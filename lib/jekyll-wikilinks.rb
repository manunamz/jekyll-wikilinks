# frozen_string_literal: true
require "jekyll"

require_relative "jekyll-wikilinks/context"
require_relative "jekyll-wikilinks/doc_manager"
require_relative "jekyll-wikilinks/link_index"
require_relative "jekyll-wikilinks/parser"

require_relative "jekyll-wikilinks/filter"
require_relative "jekyll-wikilinks/version"

Liquid::Template.register_filter(JekyllWikiLinks::TypeFilters)

module JekyllWikiLinks
  class Generator < Jekyll::Generator
		attr_accessor :site, :config, :md_docs, :doc_manager, :link_index, :parser, :graph_nodes, :graph_links

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
		GRAPH_ASSETS_LOCATION_KEY = "assets_rel_path"

    # identify missing links in doc via .invalid-wiki-link class and nested doc-text.
    REGEX_INVALID_WIKI_LINK = /invalid-wiki-link#{REGEX_NOT_GREEDY}\[\[(#{REGEX_NOT_GREEDY})\]\]/i

		def initialize(config)
			@config ||= config
			@testing ||= config['testing'] if config.keys.include?('testing')
		end

		def generate(site)
			return if disabled?
      self.old_config_warn()
			Jekyll.logger.debug "Excluded jekyll types: ", option(EXCLUDE_KEY)
			Jekyll.logger.debug "Excluded jekyll types in graph: ", option_graph(EXCLUDE_GRAPH_KEY)
      
      # setup site
			@site = site    
			@context ||= JekyllWikiLinks::Context.new(site)
      
      # setup markdown docs
			docs = []
			docs += site.pages if !exclude?(:pages)
			docs += site.docs_to_write.filter { |d| !exclude?(d.type) }
			@md_docs = docs.filter {|doc| markdown_extension?(doc.extname) }
      
      # setup helper classes
      @doc_manager = DocManager.new(@md_docs, @site.static_files)
      @parser = Parser.new(@context, @markdown_converter, @doc_manager)
      @link_index = LinkIndex.new(@site, @doc_manager)
      
      # parse + populate index
      @md_docs.each do |doc|
        @parser.parse(doc.content)
        @link_index.populate_attributes(doc, @parser.typed_link_blocks)
      end
      @link_index.process
      
      # handle graph data
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

		# config helpers

		def disabled?
			option(ENABLED_KEY) == false
		end

		def exclude?(type)
			return false unless option(EXCLUDE_KEY)
			return option(EXCLUDE_KEY).include?(type.to_s)
		end

		def has_custom_assets_path?
			return !!option_graph(GRAPH_ASSETS_LOCATION_KEY)
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

		# graph config helpers

		def disabled_graph_data?
			option_graph(ENABLED_GRAPH_DATA_KEY) == false
		end

		def excluded_in_graph?(type)
			return false unless option_graph(EXCLUDE_KEY)
			return option_graph(EXCLUDE_KEY).include?(type.to_s)
		end

		def option_graph(key)
			config[GRAPH_DATA_KEY] && config[GRAPH_DATA_KEY][key]
		end

		# graph helpers

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
			# TODO: this link calculation ends up with duplicates -- re-visit this later.
			all_links = doc.data['attributed'] + doc.data['backlinks']
			all_links.each do |link|
        linked_doc = link['doc']
				if !excluded_in_graph?(linked_doc.type)
					graph_links << {
						source: relative_url(linked_doc.url),
						target: relative_url(doc.url),
					}
				end
			end
		end

		def write_graph_data()
			assets_path = has_custom_assets_path? ? option_graph(GRAPH_ASSETS_LOCATION_KEY) : "/assets"
			if !File.directory?(File.join(site.source, assets_path))
				Jekyll.logger.error "Assets location does not exist, please create required directories for path: ", assets_path
			end
			# from: https://github.com/jekyll/jekyll/issues/7195#issuecomment-415696200
			static_file = Jekyll::StaticFile.new(site, site.source, assets_path, "graph-net-web.json")
			# TODO: make write file location more flexible -- requiring a write location configuration feels messy...
			File.write(@site.source + static_file.relative_path, JSON.dump({
				links: graph_links,
				nodes: graph_nodes,
			}))
			# tests fail without manually adding the static file, but actual site builds seem to do ok
			# ...although there does seem to be a race condition which causes a rebuild to be necessary in order to detect the graph data file
			if @testing
				@site.static_files << static_file if !@site.static_files.include?(static_file)
			end
		end

    # !! deprecated !!

    def old_config_warn()
      if config.include?("wikilinks_collection")
        Jekyll.logger.warn "As of 0.0.3, 'wikilinks_collection' is no longer used for configs. jekyll-wikilinks will scan all markdown files by default. Check README for details."
      end
    end
	end
end
