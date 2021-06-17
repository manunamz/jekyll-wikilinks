module JekyllWikiLinks
    # regex
		
    # <variables> only work with 'match' function, not with 'scan' function. :/ 
		# oh well...they are there for easier debugging...
                                                                   # capture indeces
    # REGEX_NOT_GREEDY = /[^(?!\]\])]+/i
    # REGEX_NOT_GREEDY = /(?!\]\]).*/i
    REGEX_NOT_GREEDY = /[^\]]+/i
    REGEX_LINK_EMBED = /(?<embed>(\!))/i                           # 0
    REGEX_LINK_TYPE_TXT = /(?<type-txt>([^\n\s\!\#\^\|\]]+))/i     # 1
    REGEX_FILENAME = /(?<filename>([^\\\/:\#\^\|\[\]]+))/i         # 2
    REGEX_HEADER_TXT = /(?<header-txt>([^\^\!\#\^\|\[\]]+))/i      # 3
    REGEX_BLOCK_ID_TXT = /(?<block-id>([^\|\]]+))/i                # 4
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

    # kramdown header regexes
    # atx header: https://github.com/gettalong/kramdown/blob/master/lib/kramdown/parser/kramdown/header.rb#L29
    REGEX_ATX_HEADER = /^\#{1,6}[\t ]*([^ \t].*)\n/i
    # setext header: https://github.com/gettalong/kramdown/blob/master/lib/kramdown/parser/kramdown/header.rb#L17
    REGEX_SETEXT_HEADER = /^ {0,3}([^ \t].*)\n[-=][-=]*[ \t\r\f\v]*\n/i
    # obsidian-style
    REGEX_BLOCK = /.*\s\^#{REGEX_BLOCK_ID_TXT}^[^\n]/i

    # identify missing links in doc via .invalid-wiki-link class and nested doc-name.
    REGEX_INVALID_WIKI_LINK = /invalid-wiki-link#{REGEX_NOT_GREEDY}\[\[(#{REGEX_NOT_GREEDY})\]\]/i
end
