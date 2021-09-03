# regex.rb
# regex constants defining supported file types and valid names for files, variables, or text
#

module Jekyll
  module WikiLinks
    #  <regex_variables> only work with 'match' function, not with 'scan' function. :/
    #  oh well...they are there for easier debugging...

    # supported image formats
    # from: https://docs.github.com/en/github/managing-files-in-a-repository/working-with-non-code-files/rendering-and-diffing-images
    SUPPORTED_IMG_FORMATS = Set.new(['.png', '.jpg', '.gif', '.psd', '.svg'])

    # wikilink constants
  	REGEX_LINK_LEFT = /\[\[/
    REGEX_LINK_RIGHT = /\]\]/
    REGEX_LINK_EMBED = /(?<embed>(\!))/
    REGEX_LINK_TYPE = /\s*::\s*/
    REGEX_LINK_HEADER = /\#/
    REGEX_LINK_BLOCK = /\#\^/
    REGEX_LINK_LABEL = /\|/

    # wikilink usable char requirements
    REGEX_LINK_TYPE_TXT = /(?<link-type-txt>([^\n\s\!\#\^\|\]]+))/i
    REGEX_FILENAME = /(?<filename>([^\\\/:\#\^\|\[\]]+))/i
    REGEX_HEADER_TXT = /(?<header-txt>([^\!\#\^\|\[\]]+))/i
    REGEX_BLOCK_ID_TXT = /(?<block-id>([^\\\/:\!\#\^\|\[\]^\n]+))/i
    REGEX_LABEL_TXT = /(?<label-txt>((.+?)(?=\]\])))/i

    # target markdown text (headers, lists, and blocks)
    ## kramdown regexes
    ### atx header: https://github.com/gettalong/kramdown/blob/master/lib/kramdown/parser/kramdown/header.rb#L29
    REGEX_ATX_HEADER = /^\#{1,6}[\t ]*([^ \t].*)\n/i
    ### setext header: https://github.com/gettalong/kramdown/blob/master/lib/kramdown/parser/kramdown/header.rb#L17
    REGEX_SETEXT_HEADER = /^ {0,3}([^ \t].*)\n[-=][-=]*[ \t\r\f\v]*\n/i
    ## list item: https://github.com/gettalong/kramdown/blob/master/lib/kramdown/parser/kramdown/list.rb#L49
    REGEX_BULLET = /(?<bullet>[+*-])/i
    # REGEX_LIST_ITEM = /(^ {0,3}[+*-])([\t| ].*?\n)/i
    REGEX_LIST_ITEM = /(^ {0,3}#{REGEX_BULLET})(\s(?:#{REGEX_LINK_LEFT}#{REGEX_FILENAME}#{REGEX_LINK_RIGHT}))/i
    ## new-markdown-style
    REGEX_BLOCK = /.*\s\^#{REGEX_BLOCK_ID_TXT}/i

    # wikilinks
    ## inline
    REGEX_WIKI_LINKS = %r{                            # capture indeces
      (#{REGEX_LINK_EMBED})?                          # 0
      (#{REGEX_LINK_TYPE_TXT}#{REGEX_LINK_TYPE})?     # 1
      #{REGEX_LINK_LEFT}
        #{REGEX_FILENAME}                             # 2
        (#{REGEX_LINK_HEADER}#{REGEX_HEADER_TXT})?    # 3
        (#{REGEX_LINK_BLOCK}#{REGEX_BLOCK_ID_TXT})?   # 4
        (#{REGEX_LINK_LABEL}#{REGEX_LABEL_TXT})?      # 5
      #{REGEX_LINK_RIGHT}
    }x
    ## block
    REGEX_TYPED_LINK_BLOCK = /#{REGEX_LINK_TYPE_TXT}#{REGEX_LINK_TYPE}#{REGEX_LINK_LEFT}#{REGEX_FILENAME}#{REGEX_LINK_RIGHT}\n/i
    # TODO: keep an eye on this -- using REGEX_FILENAME in two places
    REGEX_TYPED_LINK_BLOCK_LIST_COMMA = /(?:#{REGEX_LINK_TYPE_TXT}#{REGEX_LINK_TYPE}\s*(?:#{REGEX_LINK_LEFT}#{REGEX_FILENAME}#{REGEX_LINK_RIGHT})\s*|\G)\s*(?:,\s*#{REGEX_LINK_LEFT}#{REGEX_FILENAME}#{REGEX_LINK_RIGHT})\s*/i
    REGEX_TYPED_LINK_BLOCK_LIST_MKDN = /#{REGEX_LINK_TYPE_TXT}#{REGEX_LINK_TYPE}\n|\G(?:#{REGEX_LIST_ITEM}\n)/i

    # parsing for wikilinks in html
    # identify missing links in doc via .invalid-wiki-link class and nested doc-text.
    REGEX_INVALID_WIKI_LINK = /invalid-wiki-link(?:[^\]]+)\[\[(?<wiki-text>([^\]]+))\]\]/i

  end
end
