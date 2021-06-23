require_relative "naming_const"

module JekyllWikiLinks
  REGEX_LINK_EMBED = /(?<embed>(\!))/i                           # 0 (capture index for WikiLinks class)
  REGEX_LINK_TYPE = /::/
  REGEX_LINK_HEADER = /\#/
  REGEX_LINK_BLOCK = /\#\^/
  REGEX_LINK_LABEL = /\|/
  REGEX_WIKI_LINKS = %r{
    (#{REGEX_LINK_EMBED})?
    (#{REGEX_LINK_TYPE_TXT}#{REGEX_LINK_TYPE})?
    \[\[
      #{REGEX_FILENAME}
      (#{REGEX_LINK_HEADER}#{REGEX_HEADER_TXT})?
      (#{REGEX_LINK_BLOCK}#{REGEX_BLOCK_ID_TXT})?
      (#{REGEX_LINK_LABEL}#{REGEX_LABEL_TXT})?
    \]\]
  }x
  REGEX_TYPED_LINK_BLOCK = /\n#{REGEX_LINK_TYPE_TXT}#{REGEX_LINK_TYPE}\[\[#{REGEX_FILENAME}\]\]\n/i

  # it's not a parser, but a "parser"...for now...
  class Parser
    attr_accessor :doc_manager, :markdown_converter, :wikilinks, :typed_link_blocks

    # Use Jekyll's native relative_url filter
    include Jekyll::Filters::URLFilters

    def initialize(context, markdown_converter, doc_manager)
      @context ||= context
      @doc_manager ||= doc_manager
      @markdown_converter ||= markdown_converter
      @wikilinks, @typed_link_blocks = [], []
    end

    def parse(doc_content)
      @typed_link_blocks, @wikilinks = [], []
      # process blocks
      typed_link_block_matches = doc_content.scan(REGEX_TYPED_LINK_BLOCK)
      if !typed_link_block_matches.nil? && typed_link_block_matches.size != 0 
        typed_link_block_matches.each do |wl_match|
          typed_link_block_wikilink = WikiLink.new(
            nil,
            wl_match[0],
            wl_match[1],
            nil,
            nil,
            nil,
          )
          doc_content.gsub!(typed_link_block_wikilink.md_link_str, "")
          @typed_link_blocks << typed_link_block_wikilink
        end
      end
      # process inlines
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
        doc_content.sub!(
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
          "<div class=\"wiki-link-embed-link\">",
            "<a class=\"wiki-link\" href=\"#{url}\"></a>",
          "</div>",
        "</div>",
      ].join("\n").gsub!("\n", "")
    end

    def build_html_img_embed(img_file)
      "<p><span class=\"wiki-link-embed-image\"><img class=\"wiki-link-img\" src=\"#{relative_url(img_file.relative_path)}\"/></span></p>"
    end

		def build_html(wikilink)
      if wikilink.is_img?
			  linked_doc = @doc_manager.get_image_by_bname(wikilink.filename)
        if wikilink.embedded? && wikilink.is_img?
          return build_html_img_embed(linked_doc)
        end
      end
      linked_doc = @doc_manager.get_doc_by_fname(wikilink.filename)
			if !linked_doc.nil?
        link_type = wikilink.typed? ? " link-type #{wikilink.link_type}" : ""

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
            @doc_manager.get_doc_content(wikilink.filename),
            lnk_doc_rel_url
          ) if wikilink.embedded?
				elsif (link_lvl == "header" && DocManager.doc_has_header?(linked_doc, wikilink.header_txt))
					lnk_doc_rel_url += "\#" + wikilink.header_txt.downcase
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
  
  # the wikilink class knows everything about the original markdown syntax and its semantic meaning
  class WikiLink
    attr_accessor :embed, :link_type, :filename, :header_txt, :block_id, :label_txt

    FILENAME = "filename"
    HEADER_TXT = "header_txt"
    BLOCK_ID = "block_id"

    # parameters ordered by appearance in regex
    def initialize(embed, link_type, filename, header_txt, block_id, label_txt)
      # super(embed, link_type, filename, header_txt, block_id, label_txt)
      @embed ||= embed
      @link_type ||= link_type
      @filename ||= filename
      @header_txt ||= header_txt
      @block_id ||= block_id
      @label_txt ||= label_txt
    end

    # labeles are really flexible, so we need to handle them with a bit more care
    def clean_label_txt
      return @label_txt.sub("[", "\\[").sub("]", "\\]")
    end

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