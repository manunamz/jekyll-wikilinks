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
        @doc_manager ||= site.doc_mngr
        @markdown_converter ||= site.find_converter_instance(CONVERTER_CLASS)
        @wikilink_blocks, @wikilink_inlines = [], [], []
      end

      # parsing

      def parse(doc_content)
        @wikilink_blocks, @wikilink_inlines = [], [], []
        if !$wiki_conf.disabled_attributes?
          self.parse_block_singles(doc_content)
          self.parse_block_lists_mkdn(doc_content)
          self.parse_block_lists_comma(doc_content)
        end
        self.parse_inlines(doc_content)
      end

      def parse_block_singles(doc_content)
        bullet_type = ""
        typed_link_block_matches = doc_content.scan(REGEX_TYPED_LINK_BLOCK)
        if !typed_link_block_matches.nil? && typed_link_block_matches.size != 0
          typed_link_block_matches.each do |wl_match|
            link_type = wl_match[0]
            filename = wl_match[1]
            typed_link_block_wikilink = WikiLinkBlock.new(
              @doc_manager,
              link_type,
              bullet_type,
              filename,
            )
            @wikilink_blocks << typed_link_block_wikilink
            doc_content.gsub!(typed_link_block_wikilink.md_regex, "\n")
          end
        end
      end

      def parse_block_lists_comma(doc_content)
        processing_link_type = nil
        processing_wikilink_list = nil
        bullet_type = ","
        typed_link_block_list_item_matches = doc_content.scan(REGEX_TYPED_LINK_BLOCK_LIST_COMMA)
        if !typed_link_block_list_item_matches.nil? && typed_link_block_list_item_matches.size != 0
          # Match 1
          #   link-type-txt	link-type
          #   filename	link
          #   3.	alink
          # Match 2
          #   link-type-txt
          #   filename
          #   3.	blink
          # Match 3
          #   link-type-txt
          #   filename
          #   3.	clink
          typed_link_block_list_item_matches.each do |wl_match|
            link_type = wl_match[0]
            link_filename_1 = wl_match[1]
            link_filename_2 = wl_match[2]
            if !link_type.nil?
              # process previous wikilink_list
              if !processing_wikilink_list.nil? && processing_wikilink_list.has_items?
                @wikilink_blocks << processing_wikilink_list
                doc_content.gsub!(processing_wikilink_list.md_regex, "\n")
              end
              processing_link_type = link_type
              processing_wikilink_list = WikiLinkBlock.new(@doc_manager, processing_link_type, bullet_type, link_filename_1)
              processing_wikilink_list.add_item(bullet_type, link_filename_2) if !link_filename_2.nil?
            else
              Jekyll.logger.error("'processing_wikilink_list' was nil") if processing_wikilink_list.nil?
              processing_wikilink_list.add_item(bullet_type, link_filename_2)
            end
          end
          # process previous wikilink_list
          if !processing_wikilink_list.nil? && processing_wikilink_list.has_items?
            @wikilink_blocks << processing_wikilink_list
            doc_content.gsub!(processing_wikilink_list.md_regex, "\n")
          end
        end
      end

      def parse_block_lists_mkdn(doc_content)
        processing_link_type = nil
        processing_wikilink_list = nil
        bullet_type = nil
        typed_link_block_list_item_matches = doc_content.scan(REGEX_TYPED_LINK_BLOCK_LIST_MKDN)
        if !typed_link_block_list_item_matches.nil? && typed_link_block_list_item_matches.size != 0
          # Match 1
          #   link-type-txt	more-types
          #   bullet
          #   filename
          # Match 2
          #   link-type-txt
          #   bullet	*
          #   filename	alink
          # Match 3
          #   link-type-txt
          #   bullet	*
          #   filename	blink
          # Match 4
          #   link-type-txt	more-types
          #   bullet
          #   filename
          # Match 5
          #   link-type-txt
          #   bullet	+
          #   filename	alink
          # Match 6
          #   link-type-txt
          #   bullet	+
          #   filename	blink
          typed_link_block_list_item_matches.each do |wl_match|
            link_type = wl_match[0]
            bullet_type = wl_match[1]
            link_filename = wl_match[2]
            if !link_type.nil?
              # process previous wikilink_list
              if !processing_wikilink_list.nil? && processing_wikilink_list.has_items?
                @wikilink_blocks << processing_wikilink_list
                doc_content.gsub!(processing_wikilink_list.md_regex, "\n")
              end
              processing_link_type = link_type
              processing_wikilink_list = WikiLinkBlock.new(@doc_manager, processing_link_type)
            else
              Jekyll.logger.error("'processing_wikilink_list' was nil") if processing_wikilink_list.nil?
              processing_wikilink_list.add_item(bullet_type, link_filename)
            end
          end
          # process previous wikilink_list
          if !processing_wikilink_list.nil? && processing_wikilink_list.has_items?
            @wikilink_blocks << processing_wikilink_list
            doc_content.gsub!(processing_wikilink_list.md_regex, "\n")
          end
        end
      end

      def parse_inlines(doc_content)
        wikilink_matches = doc_content.scan(REGEX_WIKI_LINKS)
        if !wikilink_matches.nil? && wikilink_matches.size != 0
          wikilink_matches.each do |wl_match|
            @wikilink_inlines << WikiLinkInline.new(
              @doc_manager,
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
        if wikilink.is_img?
  			  linked_static_doc = @doc_manager.get_image_by_fname(wikilink.filename)
          if wikilink.embedded? && wikilink.is_img?
            return build_html_img_embed(linked_static_doc, is_svg=wikilink.is_img_svg?)
          end
        end
        linked_doc = @doc_manager.get_doc_by_fname(wikilink.filename)
  			if !linked_doc.nil?
          link_type = wikilink.typed? ? " #{$wiki_conf.css_name("typed")} #{wikilink.link_type}" : ""

  				# label
  				wikilink_inner_txt = wikilink.clean_label_txt if wikilink.labelled?

  				lnk_doc_rel_url = relative_url(linked_doc.url)
          # TODO not sure about downcase
  				fname_inner_txt = linked_doc['title'].downcase if wikilink_inner_txt.nil?

          link_lvl = wikilink.describe['level']
  				if (link_lvl == "file")
  					wikilink_inner_txt = "#{fname_inner_txt}" if wikilink_inner_txt.nil?
            return build_html_embed(
              linked_doc['title'],
              @doc_manager.get_doc_content(wikilink.filename),
              lnk_doc_rel_url
            ) if wikilink.embedded?
  				elsif (link_lvl == "header" && DocManager.doc_has_header?(linked_doc, wikilink.header_txt))
            # from: https://github.com/jekyll/jekyll/blob/6855200ebda6c0e33f487da69e4e02ec3d8286b7/Rakefile#L74
  					lnk_doc_rel_url += "\#" + Jekyll::Utils.slugify(wikilink.header_txt)
  					wikilink_inner_txt = "#{fname_inner_txt} > #{wikilink.header_txt}" if wikilink_inner_txt.nil?
  				elsif (link_lvl == "block" && DocManager.doc_has_block_id?(linked_doc, wikilink.block_id))
  					lnk_doc_rel_url += "\#" + wikilink.block_id.downcase
  					wikilink_inner_txt = "#{fname_inner_txt} > ^#{wikilink.block_id}" if wikilink_inner_txt.nil?
  				else
  					return '<span class="' + $wiki_conf.css_name("invalid_wiki") + '">' + wikilink.md_str + '</span>'
  				end
  				return '<a class="' + $wiki_conf.css_name("wiki") + link_type + '" href="' + lnk_doc_rel_url + '">' + wikilink_inner_txt + '</a>'
  			else
  				return '<span class="' + $wiki_conf.css_name("invalid_wiki") + '">' + wikilink.md_str + '</span>'
  			end
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
        typed_wikilinks = temp.select { |wl| wl.typed? }
        untyped_wikilinks = temp.select { |wl| !wl.typed? }
        @wikilink_inlines = typed_wikilinks.concat(untyped_wikilinks)
      end
    end

    # validation

    # def has_target_attr?(attribute)
    #   attribute.list_item.each do |li|
    #     return false if @doc_manager.get_doc_by_fname(li[1]).nil?
    #   end
    #   return true
    # end

    # def has_target_wl?(wikilink)
    #   level = wikilink.describe['level']
    #   linked_doc = @doc_manager.get_doc_by_fname(wikilink.filename)
    #   return false if linked_doc.nil?
    #   return false if level == "header" && !DocManager.doc_has_header?(linked_doc, wikilink.header_txt)
    #   return false if level == "block" && !DocManager.doc_has_block_id?(linked_doc, wikilink.block_id)
    #   return true
    # end

  end
end
