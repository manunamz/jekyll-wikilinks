# require_relative "context"
# require_relative "regex"

# module JekyllWikiLinks
#   class GraphData # < Jekyll::Generator
#     # attr_accessor :site, :config, :nodes, :links
# 		attr_accessor :nodes, :links

# 		# # config
# 		# GRAPH_DATA_KEY = "d3_graph_data"
# 		# ENABLED_KEY = "enabled"
# 		# EXCLUDE_KEY = "exclude"

#     # identify missing links in doc via .invalid-wiki-link class and nested doc-name.
#     REGEX_INVALID_WIKI_LINK = /invalid-wiki-link#{REGEX_NOT_GREEDY}\[\[(#{REGEX_NOT_GREEDY})\]\]/i

#     # def initialize(site)
#     #   @config = config
# 		# 	@site = site
# 		# 	@context = context

# 		# 	@links = []
#     #   @nodes = []
# 		# 	Jekyll.logger.debug "Excluded jekyll types in graph: ", option_graph(EXCLUDE_KEY)
# 		# end

# 		# def generate(site)
# 		# 	# TODO when gem-ified
# 		# end

#     def generate_graph_data(doc, url)
#       # return if disabled? || excluded?(doc.type)
# 			Jekyll.logger.debug "Processing graph nodes for doc: ", doc.data['title']
# 			# missing nodes
# 			missing_node_names = doc.content.scan(REGEX_INVALID_WIKI_LINK)
# 			if !missing_node_names.nil?
# 				missing_node_names.each do |missing_node_name_captures| 
# 					missing_node_name = missing_node_name_captures[0]
# 					if nodes.none? { |node| node[:id] == missing_node_name }
# 						Jekyll.logger.warn "Net-Web node missing: ", missing_node_name
# 						Jekyll.logger.warn " in: ", doc.data['slug']  
# 						nodes << {
# 							id: missing_node_name,
# 							url: '',
# 							label: missing_node_name,
# 						}
# 					end
# 					links << {
# 						source: relative_url(doc.url),
# 						target: missing_node_name,
# 					}
# 				end
# 			end
# 			# existing nodes
# 			nodes << {
# 				id: relative_url(doc.url),
# 				url: relative_url(doc.url),
# 				label: doc.data['title'],
# 			}
# 			get_backlinks(doc).each do |b|
# 				if !excluded_in_graph?(b.type)
# 					links << {
# 						source: relative_url(b.url),
# 						target: relative_url(doc.url),
# 					}
# 				end
# 			end
# 		end

# 		def write_graph_data()
#       # return if disabled?
# 			# from: https://github.com/jekyll/jekyll/issues/7195#issuecomment-415696200
# 			static_file = Jekyll::StaticFile.new(site, site.source, "/assets", "graph-net-web.json")
# 			File.write(@site.source + static_file.relative_path, JSON.dump({
# 				links: links,
# 				nodes: nodes,
# 			}))
# 		end

#     # config helpers

# 		# def disabled?
# 		# 	option_graph(ENABLED_KEY) == false
# 		# end

#     # def excluded?(type)
# 		# 	return false unless option_graph(EXCLUDE_KEY)
# 		# 	return option_graph(EXCLUDE_KEY).include?(type.to_s)
# 		# end

# 		# def option_graph(key)
# 		# 	config[GRAPH_DATA_KEY] && config[GRAPH_DATA_KEY][key]
# 		# end

#   end
# end