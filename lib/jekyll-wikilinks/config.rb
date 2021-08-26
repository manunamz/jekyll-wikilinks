# frozen_string_literal: true
require "jekyll"

module Jekyll
  module WikiLinks

    class PluginConfig
      CONFIG_KEY = "wikilinks"
      ENABLED_KEY = "enabled"
      EXCLUDE_KEY = "exclude"

      def initialize(config)
        @config ||= config
        self.old_config_warn()
      end

      def disabled?
        option(ENABLED_KEY) == false
      end

      def exclude?(type)
        return false unless option(EXCLUDE_KEY)
        return option(EXCLUDE_KEY).include?(type.to_s)
      end

      def option(key)
        @config[CONFIG_KEY] && @config[CONFIG_KEY][key]
      end

      # !! deprecated !!

      def option_exist?(key)
        @config[CONFIG_KEY] && @config[CONFIG_KEY].include?(key)
      end

      def old_config_warn()
        if @config.include?("wikilinks_collection")
          Jekyll.logger.warn "As of 0.0.3, 'wikilinks_collection' is no longer used for configs. jekyll-wikilinks will scan all markdown files by default. Check README for details."
        end
        if option_exist?("assets_rel_path")
          Jekyll.logger.warn "As of 0.0.5, 'assets_rel_path' is now 'path'."
        end
        if @config.include?("d3_graph_data")
          Jekyll.logger.warn "As of 0.0.6, 'd3_graph_data' should now be 'd3' and requires the 'jekyll-d3' plugin."
        end
      end
    end

  end
end
