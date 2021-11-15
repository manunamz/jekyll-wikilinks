require "nokogiri"
require_relative "regex"
require_relative "wikilink"

module Jekyll
  module WikiLinks

    # more of a "parser" than a parser
    class Parser
      attr_accessor :doc_manager, :markdown_converter, :wikilink_inlines, :wikilink_blocks

      # Use Jekyll's native relative_url filter
      include Jekyll::Filters::URLFilters

      CONVERTER_CLASS = Jekyll::Converters::Markdown

      def initialize(site)
        @context ||= Jekyll::WikiLinks::Context.new(site)
        # do not use @dm in parser -- it is only meant to be passed down into wikilink classes. 
        @doc_manager ||= site.doc_mngr
        @markdown_converter ||= site.find_converter_instance(CONVERTER_CLASS)
        @wikilink_blocks, @wikilink_inlines = [], []
      end

      # weblinks
      ## add 'web-link' css class to links that aren't
      ## - wikilinks
      ## - contain an excluded css class
      def add_web_css(content)
        excluded_classes = $wiki_conf.excluded_css_names
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

      # wikilinks

      # parsing

      def parse(doc_filename, doc_content)
        @wikilink_blocks, @wikilink_inlines = [], []
        if !$wiki_conf.disabled_attributes?
          self.parse_blocks(doc_filename, doc_content)
        end
        self.parse_inlines(doc_filename, doc_content)
      end

      def parse_blocks(doc_filename, doc_content)
        block_matches = doc_content.scan(REGEX_WIKI_LINK_BLOCKS)
        if !block_matches.nil? && block_matches.size != 0
          block_matches.each do |wl_match|
            # init block wikilink
            wikilink_block = WikiLinkBlock.new(
              @doc_manager,
              doc_filename,
              wl_match[0], # link_type
              wl_match[2], # bullet_type
            )
            # extract + add filenames
            items = wl_match[1]
            filename_matches = items.scan(/#{REGEX_LINK_LEFT}#{REGEX_FILENAME}#{REGEX_LINK_RIGHT}/i)
            filename_matches.each do |match|
              match.each do |fname|
                wikilink_block.add_item(fname)
              end
            end
            # replace text
            doc_content.gsub!(wikilink_block.md_regex, "\n")
            @wikilink_blocks << wikilink_block
          end
        end
      end

      def parse_inlines(doc_filename, doc_content)
        inline_matches = doc_content.scan(REGEX_WIKI_LINKS)
        if !inline_matches.nil? && inline_matches.size != 0
          inline_matches.each do |wl_match|
            @wikilink_inlines << WikiLinkInline.new(
              @doc_manager,
              doc_filename,
              wl_match[0],
              wl_match[1],
              wl_match[2],
              wl_match[3],
              wl_match[4],
              wl_match[5],
            )
          end
        end
        # replace text
        return if @wikilink_inlines.nil?
        self.sort_typed_first
        @wikilink_inlines.each do |wikilink|
          doc_content.gsub!(
            wikilink.md_regex,
            self.build_html(wikilink)
          )
        end
      end

      # building/converting

      def build_html_embed(title, content, url)
        # multi-line for readability
        return [
          "<div class=\"#{$wiki_conf.css_name("embed_wrapper")}\">",
            "<div class=\"#{$wiki_conf.css_name("embed_title")}\">",
              "#{title}",
            "</div>",
            "<div class=\"#{$wiki_conf.css_name("embed_content")}\">",
              "#{@markdown_converter.convert(content)}",
            "</div>",
            "<a class=\"#{$wiki_conf.css_name("embed_wiki_link")}\" href=\"#{url}\"></a>",
          "</div>",
        ].join("\n").gsub!("\n", "")
      end

      def build_html_img_embed(static_doc, is_svg=false)
        svg_content = ""
        if is_svg
          File.open(static_doc.path, "r") do |svg_img|
            svg_content = svg_img.read
          end
          return "<p><span class=\"#{$wiki_conf.css_name("embed_image_wrapper")}\">#{svg_content}</span></p>"
        else
          return "<p><span class=\"#{$wiki_conf.css_name("embed_image_wrapper")}\"><img class=\"#{$wiki_conf.css_name("embed_image")}\" src=\"#{relative_url(static_doc.relative_path)}\"/></span></p>"
        end
      end

  		def build_html(wikilink)
        if !wikilink.is_valid?
          return '<span class="' + $wiki_conf.css_name("invalid_wiki") + '">' + wikilink.md_str + '</span>'
        end
        # image processing
        if wikilink.embedded? && wikilink.is_img?
          return build_html_img_embed(wikilink.linked_img, is_svg=wikilink.is_img_svg?)
        end
        # markdown file processing
        linked_doc = wikilink.linked_doc
        link_type_txt = wikilink.is_typed? ? " #{$wiki_conf.css_name("typed")} #{wikilink.link_type}" : ""
        
        inner_txt = wikilink.label_txt if wikilink.labelled?
        lnk_doc_rel_url = relative_url(linked_doc.url)
        
        if (wikilink.level == "file")
          inner_txt = "#{linked_doc['title'].downcase}" if inner_txt.nil?
          return build_html_embed(
            linked_doc['title'],
            linked_doc.content,
            lnk_doc_rel_url
          ) if wikilink.embedded?
        elsif (wikilink.level == "header")
          # from: https://github.com/jekyll/jekyll/blob/6855200ebda6c0e33f487da69e4e02ec3d8286b7/Rakefile#L74
          lnk_doc_rel_url += "\#" + Jekyll::Utils.slugify(wikilink.header_txt)
          inner_txt = "#{linked_doc['title'].downcase} > #{wikilink.header_txt}" if inner_txt.nil?
        elsif (wikilink.level == "block")
          lnk_doc_rel_url += "\#" + wikilink.block_id.downcase
          inner_txt = "#{linked_doc['title'].downcase} > ^#{wikilink.block_id}" if inner_txt.nil?
        else
          Jekyll.logger.error "Invalid wikilink level"
        end
        return '<a class="' + $wiki_conf.css_name("wiki") + link_type_txt + '" href="' + lnk_doc_rel_url + '">' + inner_txt + '</a>'
  		end

      # helpers

      def sort_typed_first
        # sorting inline wikilinks is necessary so when wikilinks are replaced,
        # longer strings are replaced first so as not to accidentally overwrite 
        # substrings
        # (this is especially likely if there is a matching wikilink that 
        #  appears as both untyped and typed in a document)
        temp = @wikilink_inlines.dup
        @wikilink_inlines.clear()
        typed_wikilinks = temp.select { |wl| wl.is_typed? }
        untyped_wikilinks = temp.select { |wl| !wl.is_typed? }
        @wikilink_inlines = typed_wikilinks.concat(untyped_wikilinks)
      end
    end

  end
end
