# regex.rb
# regex constants defining supported file types and valid names for files, variables, or text
#

module Jekyll
  module WikiLinks
    #
    # supported formats
    #
    # from: https://docs.github.com/en/github/managing-files-in-a-repository/working-with-non-code-files/rendering-and-diffing-images
    SUPPORTED_IMG_FORMATS = Set.new(['.png', '.jpg', '.gif', '.psd', '.svg'])
    #
    # markdown wikilink syntax
    #
    ## wikilink usable char syntax requirements
    #
    # TODO: Fix REGEX_NOT_GREEDY
    # REGEX_NOT_GREEDY = /[^(?!\]\])]+/i
    # REGEX_NOT_GREEDY = /(?!\]\]).*/i
    REGEX_NOT_GREEDY = /[^\]]+/i
    #  <variables> only work with 'match' function, not with 'scan' function. :/
    #  oh well...they are there for easier debugging...
    #  valid naming conventions                                      # capture indeces for WikiLinks class (0 is 'embed')
    REGEX_LINK_TYPE_TXT = /(?<link-type-txt>([^\n\s\!\#\^\|\]]+))/i  # 1
    REGEX_FILENAME = /(?<filename>([^\\\/:\#\^\|\[\]]+))/i           # 2
    REGEX_HEADER_TXT = /(?<header-txt>([^\!\#\^\|\[\]]+))/i          # 3
    REGEX_BLOCK_ID_TXT = /(?<block-id>([^\\\/:\!\#\^\|\[\]]+))/i     # 4
    REGEX_LABEL_TXT = /(?<label-txt>(#{REGEX_NOT_GREEDY}))/i         # 5

    #
    # wikilink target text (headers, blocks, and lists)
    #
    ## kramdown regexes
    ### atx header: https://github.com/gettalong/kramdown/blob/master/lib/kramdown/parser/kramdown/header.rb#L29
    REGEX_ATX_HEADER = /^\#{1,6}[\t ]*([^ \t].*)\n/i
    ### setext header: https://github.com/gettalong/kramdown/blob/master/lib/kramdown/parser/kramdown/header.rb#L17
    REGEX_SETEXT_HEADER = /^ {0,3}([^ \t].*)\n[-=][-=]*[ \t\r\f\v]*\n/i
    ## list item: https://github.com/gettalong/kramdown/blob/master/lib/kramdown/parser/kramdown/list.rb#L49
    # REGEX_LIST_ITEM = /(^ {0,3}[+*-])([\t| ].*?\n)/i
    REGEX_LIST_ITEM = /(^ {0,3}[+*-])([\t| ](?:\[\[#{REGEX_FILENAME}\]\]))/i
    ## new-markdown-style
    REGEX_BLOCK = /.*\s\^#{REGEX_BLOCK_ID_TXT}^\n/i

    #
    ## wikilink special char syntax requirements
    #
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
    REGEX_TYPED_LINK_BLOCK = /#{REGEX_LINK_TYPE_TXT}#{REGEX_LINK_TYPE}\[\[#{REGEX_FILENAME}\]\]\n/i
    #
    # parsing for wikilinks in html
    #
    # identify missing links in doc via .invalid-wiki-link class and nested doc-text.
    REGEX_INVALID_WIKI_LINK = /invalid-wiki-link#{REGEX_NOT_GREEDY}\[\[(#{REGEX_NOT_GREEDY})\]\]/i
    REGEX_VALID_WIKI_LINK = /<a\sclass="wiki-link(\slink-type\s(?<link-type>([^"]+)))?"\shref="(?<link-url>([^"]+))">/i
    # REGEX_VALID_WIKI_LINK = /wiki-link[^=]*href\s*=\s*\\?"([^"\\]*)\\?"/i

  end
end
