# naming_const.rb
# regex constants defining supported file types and valid names for files, variables, or text
# 

module JekyllWikiLinks
  # TODO: Fix REGEX_NOT_GREEDY
  # REGEX_NOT_GREEDY = /[^(?!\]\])]+/i
  # REGEX_NOT_GREEDY = /(?!\]\]).*/i
  REGEX_NOT_GREEDY = /[^\]]+/i
  # <variables> only work with 'match' function, not with 'scan' function. :/ 
  # oh well...they are there for easier debugging...
  # valid naming conventions                                     # capture indeces for WikiLinks class
  REGEX_LINK_TYPE_TXT = /(?<type-txt>([^\n\s\!\#\^\|\]]+))/i     # 1
  REGEX_FILENAME = /(?<filename>([^\\\/:\#\^\|\[\]]+))/i         # 2
  REGEX_HEADER_TXT = /(?<header-txt>([^\!\#\^\|\[\]]+))/i        # 3
  REGEX_BLOCK_ID_TXT = /(?<block-id>([^\\\/:\!\#\^\|\[\]]+))/i   # 4
  REGEX_LABEL_TXT = /(?<label-txt>(#{REGEX_NOT_GREEDY}))/i       # 5
  
  # from: https://docs.github.com/en/github/managing-files-in-a-repository/working-with-non-code-files/rendering-and-diffing-images
  SUPPORTED_IMG_FORMATS = Set.new(['.png', '.jpg', '.gif', '.psd', '.svg'])
end