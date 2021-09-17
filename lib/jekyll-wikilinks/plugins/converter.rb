require "jekyll"
require "nokogiri"

module Jekyll
  module WikiLinks

    class WebLinkConverter < Jekyll::Converter
      priority :low

      # config
      CSS_KEY = "css"
      CONFIG_KEY = "wikilinks"
      EXCLUDE_KEY = "exclude"
      # link types
      # WEB_KEY = "web"
      # WIKIL_KEY = "wiki"
      # INVALID_KEY = "invalid"
      # WIKI_EMBED_KEY = "wiki_embed"

      def matches(ext)
        ext =~ /^\.md$/i
      end

      def output_ext(ext)
        ".html"
      end

      # add 'web-link' css class to links that aren't
      # - wikilinks
      # - contain an excluded css class
      def convert(content)
        excluded_classes = option_css(EXCLUDE_KEY)
        if excluded_classes.nil? || excluded_classes.empty?
          css_def = "a:not(.#{$wiki_conf.css_name("wiki")}):not(.#{$wiki_conf.css_name("embed_wiki_link")})"
        else
          css_def = "a:not(.#{$wiki_conf.css_name("wiki")}):not(.#{$wiki_conf.css_name("embed_wiki_link")}):not(.#{excluded_classes.join("):not(.")})"
        end
        parsed_content = Nokogiri::HTML::fragment(content)
        parsed_content.css(css_def).each do |link|
          link.add_class('web-link')
        end
        content = parsed_content.to_html
      end

      # config helpers

      def option_css(key)
        @config[CONFIG_KEY] && @config[CONFIG_KEY][CSS_KEY] && @config[CONFIG_KEY][CSS_KEY][key]
      end
    end

  end
end
