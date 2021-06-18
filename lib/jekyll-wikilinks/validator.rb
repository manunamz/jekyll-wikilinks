module JekyllWikiLinks
	# this is essentially an abstract class for now
  class Validator
		# kramdown header regexes
		# atx header: https://github.com/gettalong/kramdown/blob/master/lib/kramdown/parser/kramdown/header.rb#L29
		REGEX_ATX_HEADER = /^\#{1,6}[\t ]*([^ \t].*)\n/i
		# setext header: https://github.com/gettalong/kramdown/blob/master/lib/kramdown/parser/kramdown/header.rb#L17
		REGEX_SETEXT_HEADER = /^ {0,3}([^ \t].*)\n[-=][-=]*[ \t\r\f\v]*\n/i
		# obsidian-style
		REGEX_BLOCK = /.*\s\^#{REGEX_BLOCK_ID_TXT}^\n/i

		def self.get_linked_doc(md_docs, filename)
      return nil if filename.nil?
			docs = md_docs.select{ |d| File.basename(d.basename, File.extname(d.basename)) == filename }
			return nil if docs.nil? || docs.size > 1
			return docs[0]
		end

		def self.doc_has_header?(doc, header)
			return nil if header.nil?
			# leading + trailing whitespace is ignored when matching headers
			header_results = doc.content.scan(REGEX_ATX_HEADER).flatten.map { |htxt| htxt.strip } 
			setext_header_results = doc.content.scan(REGEX_SETEXT_HEADER).flatten.map { |htxt| htxt.strip } 
			return header_results.include?(header.strip) || setext_header_results.include?(header.strip)
		end

		def self.doc_has_block_id?(doc, block_id)
      return nil if block_id.nil?
			# leading + trailing whitespace is ignored when matching blocks
			block_id_results = doc.content.scan(REGEX_BLOCK).flatten.map { |bid| bid.strip } 
			return block_id_results.include?(block_id)
		end
  end
end