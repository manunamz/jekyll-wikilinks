require_relative "regex"

module Jekyll
  module WikiLinks

    # more of a "parser" than a parser
    class Parser
      attr_accessor :doc_manager, :markdown_converter, :wikilinks, :typed_link_blocks, :typed_link_block_lists

      # Use Jekyll's native relative_url filter
      include Jekyll::Filters::URLFilters

      CONVERTER_CLASS = Jekyll::Converters::Markdown

      def initialize(site)
        @context ||= Jekyll::WikiLinks::Context.new(site)
        @doc_manager ||= site.doc_mngr
        @markdown_converter ||= site.find_converter_instance(CONVERTER_CLASS)
        @typed_link_block_lists, @typed_link_blocks, @wikilinks = [], [], []
      end

      def parse(doc_content)
        @typed_link_block_lists, @typed_link_blocks, @wikilinks = [], [], []
        self.parse_blocks(doc_content)
        self.parse_block_lists_mkdn(doc_content)
        self.parse_block_lists_comma(doc_content)
        self.parse_inlines(doc_content)
      end

      def parse_blocks(doc_content)
        bullet_type = ""
        typed_link_block_matches = doc_content.scan(REGEX_TYPED_LINK_BLOCK)
        if !typed_link_block_matches.nil? && typed_link_block_matches.size != 0
          typed_link_block_matches.each do |wl_match|
            link_type = wl_match[0]
            filename = wl_match[1]
            typed_link_block_wikilink = WikiLinkBlock.new(
              link_type,
              bullet_type,
              filename,
            )
            @typed_link_block_lists << typed_link_block_wikilink
            doc_content.gsub!(typed_link_block_wikilink.md_regex, "")
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
                @typed_link_block_lists << processing_wikilink_list
                doc_content.gsub!(processing_wikilink_list.md_regex, "")
              end
              processing_link_type = link_type
              processing_wikilink_list = WikiLinkBlock.new(processing_link_type, bullet_type, link_filename_1)
              processing_wikilink_list.add_item(bullet_type, link_filename_2) if !link_filename_2.nil?
            else
              Jekyll.logger.error("'processing_wikilink_list' was nil") if processing_wikilink_list.nil?
              processing_wikilink_list.add_item(bullet_type, link_filename_2)
            end
          end
          # process previous wikilink_list
          if !processing_wikilink_list.nil? && processing_wikilink_list.has_items?
            @typed_link_block_lists << processing_wikilink_list
            doc_content.gsub!(processing_wikilink_list.md_regex, "")
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
                @typed_link_block_lists << processing_wikilink_list
                doc_content.gsub!(processing_wikilink_list.md_regex, "")
              end
              processing_link_type = link_type
              processing_wikilink_list = WikiLinkBlock.new(processing_link_type)
            else
              Jekyll.logger.error("'processing_wikilink_list' was nil") if processing_wikilink_list.nil?
              processing_wikilink_list.add_item(bullet_type, link_filename)
            end
          end
          # process previous wikilink_list
          if !processing_wikilink_list.nil? && processing_wikilink_list.has_items?
            @typed_link_block_lists << processing_wikilink_list
            doc_content.gsub!(processing_wikilink_list.md_regex, "")
          end
        end
      end

      def parse_inlines(doc_content)
        # @wikilinks = []
        wikilink_matches = doc_content.scan(REGEX_WIKI_LINKS)
        if !wikilink_matches.nil? && wikilink_matches.size != 0
          wikilink_matches.each do |wl_match|
            @wikilinks << WikiLink.new(
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
        return if @wikilinks.nil?
        @wikilinks.each do |wikilink|
          doc_content.gsub!(
            # TODO: Keep this around just in case something breaks -- remove 2021.10.01 (also gsub! -> sub!)
            # wikilink.md_link_regex,
            wikilink.md_link_regex,
            self.build_html(wikilink)
          )
        end
      end

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
            "<a class=\"wiki-link-embed-link\" href=\"#{url}\"></a>",
          "</div>",
        ].join("\n").gsub!("\n", "")
      end

      def build_html_img_embed(static_doc, is_svg=false)
        svg_content = ""
        if is_svg
          File.open(static_doc.path, "r") do |svg_img|
            svg_content = svg_img.read
          end
          return "<p><span class=\"wiki-link-embed-image\">#{svg_content}</span></p>"
        else
          return "<p><span class=\"wiki-link-embed-image\"><img class=\"wiki-link-img\" src=\"#{relative_url(static_doc.relative_path)}\"/></span></p>"
        end
      end

  		def build_html(wikilink)
        if wikilink.is_img?
  			  linked_static_doc = @doc_manager.get_image_by_bname(wikilink.filename)
          if wikilink.embedded? && wikilink.is_img?
            return build_html_img_embed(linked_static_doc, is_svg=wikilink.is_img_svg?)
          end
        end
        linked_doc = @doc_manager.get_doc_by_fname(wikilink.filename)
  			if !linked_doc.nil?
          link_type = wikilink.typed? ? " link-type #{wikilink.link_type}" : ""

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
  					return '<span title="Content not found." class="invalid-wiki-link">' + wikilink.md_link_str + '</span>'
  				end
  				return '<a class="wiki-link' + link_type + '" href="' + lnk_doc_rel_url + '">' + wikilink_inner_txt + '</a>'
  			else
  				return '<span title="Content not found." class="invalid-wiki-link">' + wikilink.md_link_str + '</span>'
  			end
  		end
    end

    class WikiLinkBlock
      attr_accessor :link_type, :list_items

      # parameters ordered by appearance in regex
      def initialize(link_type, bullet_type=nil, filename=nil)
        @link_type ||= link_type
        @list_items = [] # li[0] = bullet_type; li[1] = filename
        @list_items << [ bullet_type, filename ] if !bullet_type.nil? && !filename.nil?
      end

      def add_item(bullet_type, filename)
        return if bullet_type.nil? || bullet_type.empty? || filename.nil? || filename.empty?
        @list_items << [ bullet_type, filename ]
      end

      def md_regex
        if typed? && has_items?
          # single
          if bullet_type?.empty?
            link_type = %r{#{@link_type}#{REGEX_LINK_TYPE}}
            list_item_strs = @list_items.map { |li| /\[\[#{li[1]}\]\]\n/i }
            md_link_regex = /#{link_type}#{list_item_strs.join("")}/i
          # bullet-comma
          elsif bullet_type? == ","
            tmp_list_items = @list_items.dup
            first_item = tmp_list_items.shift()
            link_type = /#{@link_type}#{REGEX_LINK_TYPE}\[\[#{first_item[1]}\]\]\s*/i
            list_item_strs = tmp_list_items.map { |li| /#{li[0]}\s*\[\[#{li[1]}\]\]\s*/i }
            md_link_regex = /#{link_type}#{list_item_strs.join('')}/i
          # bullet-md
          elsif !bullet_type?.match(REGEX_BULLET).nil?
            link_type = %r{#{@link_type}#{REGEX_LINK_TYPE}\n}
            list_item_strs = @list_items.map { |li| /#{Regexp.escape(li[0])}\s\[\[#{li[1]}\]\]\n/i }
            md_link_regex = /#{link_type}#{list_item_strs.join("")}/i
          else
            Jekyll.logger.error("Not a valid bullet_type: #{bullet_type?}")
          end
          return md_link_regex
        else
          Jekyll.logger.error("WikiLinkBlockList.md_regex error")
        end
      end

      def md_str
        if typed? && has_items?
          if bullet_type? == ","
            link_type = "#{@link_type}::"
            list_item_strs = @list_items.map { |li| "\[\[#{li[1]}\]\]#{li[0]}" }
            md_link_str = (link_type + list_item_strs.join('')).delete_suffix(",")
          elsif "+*-".include?(bullet_type?)
            link_type = "#{@link_type}::\n"
            list_item_strs = @list_items.map { |li| li[0] + " \[\[#{li[1]}\]\]\n" }
            md_link_str = link_type + list_item_strs.join('')
          else
            Jekyll.logger.error("Not a valid bullet_type: #{bullet_type?}")
          end
          return md_link_str
        else
          Jekyll.logger.error("WikiLinkBlockList.md_str error")
        end
      end

      def bullet_type?
        bullets = @list_items.map { |li| li[0] }
        return bullets.uniq.first if bullets.uniq.size == 1
      end

      def has_items?
        return !@list_items.nil? && !@list_items.empty?
      end

      def typed?
        return !@link_type.nil? && !@link_type.empty?
      end
    end

    # the wikilink class knows everything about the original markdown syntax and its semantic meaning
    class WikiLink
      attr_accessor :embed, :link_type, :filename, :header_txt, :block_id, :label_txt

      FILENAME = "filename"
      HEADER_TXT = "header_txt"
      BLOCK_ID = "block_id"

      # parameters ordered by appearance in regex
      def initialize(embed, link_type, filename, header_txt, block_id, label_txt)
        @embed ||= embed
        @link_type ||= link_type
        @filename ||= filename
        @header_txt ||= header_txt
        @block_id ||= block_id
        @label_txt ||= label_txt
      end

      # labels are really flexible, so we need to handle them with a bit more care
      def clean_label_txt
        return @label_txt.sub("[", "\\[").sub("]", "\\]")
      end

      # TODO: remove this once parsing is migrated to nokogiri...?
      def md_link_str
        embed = embedded? ? "!" : ""
        link_type = typed? ? "#{@link_type}::" : ""
        filename = described?(FILENAME) ? @filename : ""
        if described?(HEADER_TXT)
          header = "\##{@header_txt}"
          block = ""
        elsif described?(BLOCK_ID)
          header = ""
          block = "\#\^#{@block_id}"
        elsif !described?(FILENAME)
          Jekyll.logger.error "Invalid link level in 'md_link_str'. See WikiLink's 'md_link_str' for details"
        end
        label_ = labelled? ? "\|#{@label_txt}" : ""
        return "#{embed}#{link_type}\[\[#{filename}#{header}#{block}#{label_}\]\]"
      end

      def md_link_regex
        regex_embed = embedded? ? REGEX_LINK_EMBED : %r{}
        regex_link_type = typed? ? %r{#{@link_type}#{REGEX_LINK_TYPE}} : %r{}
        filename = described?(FILENAME) ? @filename : ""
        if described?(HEADER_TXT)
          header = %r{#{REGEX_LINK_HEADER}#{@header_txt}}
          block = %r{}
        elsif described?(BLOCK_ID)
          header = %r{}
          block = %r{#{REGEX_LINK_BLOCK}#{@block_id}}
        elsif !described?(FILENAME)
          Jekyll.logger.error "Invalid link level in regex. See WikiLink's 'md_link_regex' for details"
        end
        label_ =  labelled? ? %r{#{REGEX_LINK_LABEL}#{clean_label_txt}} : %r{}
        return %r{#{regex_embed}#{regex_link_type}\[\[#{filename}#{header}#{block}#{label_}\]\]}
      end

      def describe
        return {
          'level' => level,
          'labelled' => labelled?,
          'embedded' => embedded?,
          'typed_link' => typed?,
        }
      end

      def labelled?
        return !@label_txt.nil? && !@label_txt.empty?
      end

      def typed?
        return !@link_type.nil? && !@link_type.empty?
      end

      def embedded?
        return !@embed.nil? && @embed == "!"
      end

      def is_img?
        # github supported image formats: https://docs.github.com/en/github/managing-files-in-a-repository/working-with-non-code-files/rendering-and-diffing-images
        return SUPPORTED_IMG_FORMATS.any?{ |ext| ext == File.extname(@filename).downcase }
      end

      def is_img_svg?
        return File.extname(@filename).downcase == ".svg"
      end

      def described?(chunk)
        return (!@filename.nil? && !@filename.empty?) if chunk == FILENAME
        return (!@header_txt.nil? && !@header_txt.empty?) if chunk == HEADER_TXT
        return (!@block_id.nil? && !@block_id.empty?) if chunk == BLOCK_ID
        Jekyll.logger.error "There is no link level '#{chunk}' in WikiLink Struct"
      end

      def level
        return "file" if described?(FILENAME) && !described?(HEADER_TXT) && !described?(BLOCK_ID)
        return "header" if described?(FILENAME) && described?(HEADER_TXT) && !described?(BLOCK_ID)
        return "block" if described?(FILENAME) && !described?(HEADER_TXT) && described?(BLOCK_ID)
        return "invalid"
      end
    end

  end
end