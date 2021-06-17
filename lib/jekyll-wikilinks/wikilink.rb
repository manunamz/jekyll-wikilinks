require_relative "regex"

module JekyllWikiLinks
  # the wikilink class knows everything about the original markdown syntax and its semantic meaning
  class WikiLink
    attr_accessor :embed, :link_type, :filename, :header_txt, :block_id, :alias_txt

    FILENAME = "filename"
    HEADER_TXT = "header_txt"
    BLOCK_ID = "block_id"

    # parameters ordered by appearance in regex
    def initialize(embed, link_type, filename, header_txt, block_id, alias_txt)
      # super(embed, link_type, filename, header_txt, block_id, alias_txt)
      @embed ||= embed
      @link_type ||= link_type
      @filename ||= filename
      @header_txt ||= header_txt
      @block_id ||= block_id
      @alias_txt ||= alias_txt
    end

    # aliases are really flexible, so we need to handle them with a bit more care
    def clean_alias_txt
      return @alias_txt.sub("[", "\\[").sub("]", "\\]")
    end

    def md_link_str
      embed = embedded? ? "!" : ""
      link_type = typed? ? "#{@link_type}::" : ""
      filename = exists?(FILENAME) ? @filename : ""
      if exists?(HEADER_TXT)
        header = "\##{@header_txt}"
        block = ""
      elsif exists?(BLOCK_ID)
        header = ""
        block = "\#\^#{@block_id}"
      elsif !exists?(FILENAME)
        Jekyll.logger.error "Invalid link level in 'md_link_str'. See WikiLink's 'md_link_str' for details"
      end
      alias_ = aliased? ? "\|#{@alias_txt}" : ""
      return "#{embed}#{link_type}\[\[#{filename}#{header}#{block}#{alias_}\]\]"
    end

    def md_link_regex
      regex_embed = embedded? ? REGEX_EMBED : %r{}
      regex_link_type = typed? ? %r{#{@link_type}#{REGEX_LINK_TYPE}} : %r{}
      filename = exists?(FILENAME) ? @filename : ""
      if exists?(HEADER_TXT)
        header = %r{#{REGEX_HEADER}#{@header_txt}}
        block = %r{}
      elsif exists?(BLOCK_ID)
        header = %r{}
        block = %r{#{REGEX_BLOCK}#{@block_id}}
      elsif !exists?(FILENAME)
        Jekyll.logger.error "Invalid link level in regex. See WikiLink's 'md_link_regex' for details"
      end
      alias_ =  aliased? ? %r{#{REGEX_ALIAS}#{clean_alias_txt}} : %r{}
      return %r{#{regex_embed}#{regex_link_type}\[\[#{filename}#{header}#{block}#{alias_}\]\]}
    end

    def describe
      return {
        'level' => level,
        'aliased' => aliased?,
        'embedded' => embedded?,
        'typed_link' => typed?,
      }
    end

    def aliased?
      return !@alias_txt.nil? && !@alias_txt.empty?
    end

    def typed?
      return !@link_type.nil? && !@link_type.empty?
    end

    def embedded?
      return !@embed.nil? && @embed == "!"
    end

    def exists?(chunk)
      return (!@filename.nil? && !@filename.empty?) if chunk == FILENAME
      return (!@header_txt.nil? && !@header_txt.empty?) if chunk == HEADER_TXT
      return (!@block_id.nil? && !@block_id.empty?) if chunk == BLOCK_ID
      Jekyll.logger.error "There is no link level '#{chunk}' in WikiLink Struct"
    end

    def level
      return "file" if exists?(FILENAME) && !exists?(HEADER_TXT) && !exists?(BLOCK_ID)
      return "header" if exists?(FILENAME) && exists?(HEADER_TXT) && !exists?(BLOCK_ID)    
      return "block" if exists?(FILENAME) && !exists?(HEADER_TXT) && exists?(BLOCK_ID)
      return "invalid"
    end
  end
end