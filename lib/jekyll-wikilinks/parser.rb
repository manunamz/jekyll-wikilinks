require_relative "img_format_const"

module JekyllWikiLinks
  # <variables> only work with 'match' function, not with 'scan' function. :/ 
  # oh well...they are there for easier debugging...
                                                                  # capture indeces
  # TODO: Fix REGEX_NOT_GREEDY
  # REGEX_NOT_GREEDY = /[^(?!\]\])]+/i
  # REGEX_NOT_GREEDY = /(?!\]\]).*/i
  REGEX_NOT_GREEDY = /[^\]]+/i
  REGEX_LINK_EMBED = /(?<embed>(\!))/i                           # 0
  REGEX_LINK_TYPE_TXT = /(?<type-txt>([^\n\s\!\#\^\|\]]+))/i     # 1
  REGEX_FILENAME = /(?<filename>([^\\\/:\#\^\|\[\]]+))/i         # 2
  REGEX_HEADER_TXT = /(?<header-txt>([^\!\#\^\|\[\]]+))/i        # 3
  REGEX_BLOCK_ID_TXT = /(?<block-id>([^\\\/:\!\#\^\|\[\]]+))/i   # 4
  REGEX_LABEL_TXT = /(?<label-txt>(#{REGEX_NOT_GREEDY}))/i       # 5
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

  # it's not a parser, but a "parser"...for now...
  class Parser
    attr_accessor :wikilinks

    def initialize(doc)
      # handle block-lvl typed links
      wikilink_matches = doc.content.scan(REGEX_WIKI_LINKS)
      @wikilinks = [] 
      return if wikilink_matches.nil? || wikilink_matches.size == 0
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