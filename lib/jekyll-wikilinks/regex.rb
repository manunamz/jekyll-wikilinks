module JekyllWikiLinks
    # regex
		
    # <variables> only work with 'match' function, not with 'scan' function. :/ 
		# oh well...they are there for easier debugging...
    # capture index
    # REGEX_NOT_GREEDY = /[^(?!\]\])]+/i
    # REGEX_NOT_GREEDY = /(?!\]\]).*/i
    REGEX_NOT_GREEDY = /[^\]]+/i
    REGEX_EMBED = /(?<embed>(\!))/i                                      # 0
    REGEX_LINK_TYPE_TXT = /(?<type-txt>([^\n\s\!\#\^\|\]]+))/i                # 1
    REGEX_FILENAME = /(?<filename>([^\\\/:\#\^\|\[\]]+))/i               # 2
    REGEX_HEADER_TXT = /(?<header-txt>([^\^\!\#\^\|\[\]]+))/i            # 3
    REGEX_BLOCK_ID_TXT = /(?<block-txt>([^\|\]]+))/i                     # 4
    REGEX_ALIAS_TXT = /(?<alias-txt>(#{REGEX_NOT_GREEDY}))/i             # 5
    REGEX_LINK_TYPE = /::/
    REGEX_HEADER = /\#/
    REGEX_BLOCK = /\#\^/
    REGEX_ALIAS = /\|/
    REGEX_WIKI_LINKS = %r{
      (#{REGEX_EMBED})?
      (#{REGEX_LINK_TYPE_TXT}#{REGEX_LINK_TYPE})?
      \[\[
        #{REGEX_FILENAME}
        (#{REGEX_HEADER}#{REGEX_HEADER_TXT})?
        (#{REGEX_BLOCK}#{REGEX_BLOCK_ID_TXT})?
        (#{REGEX_ALIAS}#{REGEX_ALIAS_TXT})?
      \]\]
    }x
    # REGEX_WIKI_LINKS_ONE_LINE = /(?<embed>\!)?((?<type>([^\n\s\!\#\^\|\]]+))::)?\[\[(?<filename>([^\\\/:\#\^\|\[\]]+))(\#(?<header-txt>([^\!\^\|\]]+)))?(\#\^(?<block-id>([^\|\]]+)))*(\|(?<alias-text>((?!\]\]).*)))?\]\]/i
    
    # identify missing links in doc via .invalid-wiki-link class and nested doc-name.
    REGEX_INVALID_WIKI_LINK = /invalid-wiki-link#{REGEX_NOT_GREEDY}\[\[(#{REGEX_NOT_GREEDY})\]\]/i

    # kramdown header regexes
    # atx header: https://github.com/gettalong/kramdown/blob/master/lib/kramdown/parser/kramdown/header.rb#L29
    REGEX_ATX_HEADER = /^\#{1,6}[\t ]*([^ \t].*)\n/i
    # setext header: https://github.com/gettalong/kramdown/blob/master/lib/kramdown/parser/kramdown/header.rb#L17
    REGEX_SETEXT_HEADER = /^ {0,3}([^ \t].*)\n[-=][-=]*[ \t\r\f\v]*\n/i
end
