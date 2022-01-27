# wiki data structures
require_relative "regex"

module Jekyll
  module WikiLinks

    # wikilink classes know everything about the original markdown syntax and its semantic meaning

    class WikiLinkBlock
      attr_accessor :link_type, :filenames

      # parameters ordered by appearance in regex
      def initialize(doc_mngr, context_filename, link_type, bullet_type=nil)
        @doc_mngr ||= doc_mngr
        @context_filename ||= context_filename
        @link_type ||= link_type
        @bullet_type ||= bullet_type
        @filenames = []
      end

      def add_item(filename)
        Jekyll.logger.error("Jekyll-Wikilinks: 'filename' required") if filename.nil? || filename.empty?
        @filenames << filename
      end

      # data

      def md_regex
        if !is_typed? || !has_filenames? 
          Jekyll.logger.error("Jekyll-Wikilinks: WikiLinkBlock.md_regex error -- type: #{@link_type}, fnames: #{@filenames.inspect}, for: #{@context_filename}")
        end
        # comma (including singles)
        if @bullet_type.nil?
          link_type = /#{@link_type}#{REGEX_LINK_TYPE}/i
          tmp_filenames = @filenames.dup
          first_filename = /\s*#{REGEX_LINK_LEFT}#{tmp_filenames.shift()}#{REGEX_LINK_RIGHT}\s*/i
          filename_strs = tmp_filenames.map { |f| /,\s*#{REGEX_LINK_LEFT}#{f}#{REGEX_LINK_RIGHT}\s*/i }
          md_regex = /#{link_type}#{first_filename}#{filename_strs.join('')}\n/i
        # mkdn
        elsif !@bullet_type.match(REGEX_BULLET).nil?
          link_type = /#{@link_type}#{REGEX_LINK_TYPE}\n/i
          filename_strs = @filenames.map { |f| /\s{0,3}#{Regexp.escape(@bullet_type)}\s#{REGEX_LINK_LEFT}#{f}#{REGEX_LINK_RIGHT}\n/i }
          md_regex = /#{link_type}#{filename_strs.join("")}/i
        else
          Jekyll.logger.error("Jekyll-Wikilinks: WikiLinkBlock.bullet_type error: #{@bullet_type}")
        end
        return md_regex
      end

      def md_str
        if !is_typed? || !has_filenames?
          Jekyll.logger.error("Jekyll-Wikilinks: WikiLinkBlockList.md_str error -- type: #{@link_type}, fnames: #{@filenames.inspect}, for: #{@context_filename}")
        end
        # comma (including singles)
        if @bullet_type.nil?
          link_type = "#{@link_type}::"
          filename_strs = @filenames.map { |f| "\[\[#{f}\]\]," }
          md_str = (link_type + filename_strs.join('')).delete_suffix(",")
        # mkdn
        elsif !@bullet_type.match(REGEX_BULLET).nil?
          link_type = "#{@link_type}::\n"
          filename_strs = @filenames.map { |f| li[0] + " \[\[#{li[1]}\]\]\n" }
          md_str = link_type + filename_strs.join('')
        else
          Jekyll.logger.error("Jekyll-Wikilinks: 'bullet_type' invalid: #{@bullet_type}")
        end
        return md_str
      end

      def urls
        # return @filenames.map { |f| @doc_mngr.get_doc_by_fname(f).url }.compact()
        urls = []
        @filenames.each do |f|
          doc = @doc_mngr.get_doc_by_fname(f)
          urls << doc.url if !doc.nil?
        end
        return urls
      end
      
      # 'fm' -> frontmatter

      def context_fm_data
        return {
          'type' => @link_type,
          'urls' => [self.context_doc.url],
        }
      end

      def linked_fm_data
        valid_urls = self.urls.select{ |url| @doc_mngr.get_doc_by_url(url) }
        return {
          'type' => @link_type,
          'urls' => valid_urls,
        }
      end

      def context_doc
        return @doc_mngr.get_doc_by_fname(@context_filename)
      end

      def linked_docs
        docs = [] 
        @filenames.each do |f|
          doc = @doc_mngr.get_doc_by_fname(f)
          docs << doc if !doc.nil?
        end
        return docs
      end

      def missing_doc_filenames
        missing_doc_fnames = [] 
        @filenames.each do |f|
          doc = @doc_mngr.get_doc_by_fname(f)
          missing_doc_fnames << f if doc.nil?
        end
        return missing_doc_fnames
      end

      # descriptor methods

      def has_filenames?
        return !@filenames.nil? && !@filenames.empty?
      end

      def is_typed?
        return !@link_type.nil? && !@link_type.empty?
      end

      # validation methods

      def is_valid?
        all_filenames_missing = linked_docs.empty?
        return false if !is_typed? || !has_filenames? || all_filenames_missing
        return true
      end
    end

    class WikiLinkInline
      attr_accessor :context_filename, :embed, :link_type, :file_path, :path_type, :filename, :header_txt, :block_id, :label_txt

      FILE_PATH = "file_path"
      FILENAME = "filename"
      HEADER_TXT = "header_txt"
      BLOCK_ID = "block_id"

      # parameters ordered by appearance in regex
      def initialize(doc_mngr, context_filename, embed, link_type, file_string, header_txt, block_id, label_txt)
        if file_string.include?('/') && file_string[0] == '/'
          @path_type = "absolute"
          @file_path ||= file_string[1...] # remove leading '/' to match `jekyll_collection_doc.relative_path`
          @filename ||= file_string.split('/').last
        elsif file_string.include?('/') && file_string[0] != '/'
          Jekyll.logger.error("Jekyll-Wikilinks: Relative file paths are not yet supported, please use absolute file paths that start with '/' for #{file_string}")
          # todo:
          # @path_type = "relative"
        else
          @filename ||= file_string
        end
        @doc_mngr ||= doc_mngr
        @context_filename ||= context_filename
        @embed ||= embed
        @link_type ||= link_type
        @header_txt ||= header_txt
        @block_id ||= block_id
        @label_txt ||= label_txt
      end

      # escape square brackets if they appear in label text
      def label_txt
        return @label_txt.sub("[", "\\[").sub("]", "\\]")
      end

      # data

      def md_regex
        regex_embed = embedded? ? REGEX_LINK_EMBED : %r{}
        regex_link_type = is_typed? ? %r{#{@link_type}#{REGEX_LINK_TYPE}} : %r{}
        if !@file_path.nil?
          file_string = described?(FILE_PATH) ? @file_path : ""
          file_string = '/' + file_string if @path_type == "absolute"
        else
          file_string = described?(FILENAME) ? @filename : ""
        end
        if described?(HEADER_TXT)
          header = %r{#{REGEX_LINK_HEADER}#{@header_txt}}
          block = %r{}
        elsif described?(BLOCK_ID)
          header = %r{}
          block = %r{#{REGEX_LINK_BLOCK}#{@block_id}}
        elsif !described?(FILENAME) && !described?(FILE_PATH)
          Jekyll.logger.error("Jekyll-Wikilinks: WikiLinkInline.md_regex error")
        end
        label_ =  labelled? ? %r{#{REGEX_LINK_LABEL}#{label_txt}} : %r{}
        return %r{#{regex_embed}#{regex_link_type}#{REGEX_LINK_LEFT}#{file_string}#{header}#{block}#{label_}#{REGEX_LINK_RIGHT}}
      end

      def md_str
        embed = embedded? ? "!" : ""
        link_type = is_typed? ? "#{@link_type}::" : ""
        if !@file_path.nil?
          file_string = described?(FILE_PATH) ? @file_path : ""
          file_string = '/' + file_string if @path_type == "absolute"
        else
          file_string = described?(FILENAME) ? @filename : ""
        end
        if described?(HEADER_TXT)
          header = "\##{@header_txt}"
          block = ""
        elsif described?(BLOCK_ID)
          header = ""
          block = "\#\^#{@block_id}"
        elsif !described?(FILENAME) && !described?(FILE_PATH)
          Jekyll.logger.error("Jekyll-Wikilinks: WikiLinkInline.md_str error")
        end
        label_ = labelled? ? "\|#{@label_txt}" : ""
        return "#{embed}#{link_type}\[\[#{file_string}#{header}#{block}#{label_}\]\]"
      end

      # 'fm' -> frontmatter

      def context_fm_data
        return {
          'type' => @link_type,
          'url' => self.context_doc.url,
        }
      end

      def linked_fm_data
        return {
          'type' => @link_type,
          'url' => self.linked_doc.url,
        }
      end

      def context_doc
        return @doc_mngr.get_doc_by_fname(@context_filename)
      end

      def linked_doc
        # by file path
        return @doc_mngr.get_doc_by_fpath(@file_path) if !@file_path.nil?
        # by filename
        return @doc_mngr.get_doc_by_fname(@filename) if @file_path.nil?
        return nil
      end

      def linked_img
        return @doc_mngr.get_image_by_fname(@filename) if self.is_img?
        return nil
      end

      # descriptor methods

      # def describe
      #   return {
      #     'level' => level,
      #     'labelled' => labelled?,
      #     'embedded' => embedded?,
      #     'typed_link' => is_typed?,
      #   }
      # end

      def labelled?
        return !@label_txt.nil? && !@label_txt.empty?
      end

      def is_typed?
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

      # this method helps to make the 'WikiLinkInline.level' code read like a clean truth table.
      def described?(chunk)
        return (!@file_path.nil? && !@file_path.empty?) if chunk == FILE_PATH
        return (!@filename.nil? && !@filename.empty?) if chunk == FILENAME
        return (!@header_txt.nil? && !@header_txt.empty?) if chunk == HEADER_TXT
        return (!@block_id.nil? && !@block_id.empty?) if chunk == BLOCK_ID
        Jekyll.logger.error("Jekyll-Wikilinks: There is no link level '#{chunk}' in the WikiLink Class")
      end

      def level
        return "file_path" if described?(FILE_PATH) && described?(FILENAME) && !described?(HEADER_TXT) && !described?(BLOCK_ID)
        return "filename"  if !described?(FILE_PATH) && described?(FILENAME) && !described?(HEADER_TXT) && !described?(BLOCK_ID)
        return "header"    if (described?(FILE_PATH) || described?(FILENAME)) && described?(HEADER_TXT) && !described?(BLOCK_ID)
        return "block"     if (described?(FILE_PATH) || described?(FILENAME)) && !described?(HEADER_TXT) && described?(BLOCK_ID)
        return "invalid"
      end

      # validation methods

      def is_valid?
        return false if !@doc_mngr.file_exists?(@filename, @file_path)
        return false if (self.level == "header") && !@doc_mngr.doc_has_header?(self.linked_doc, @header_txt)
        return false if (self.level == "block") && !@doc_mngr.doc_has_block_id?(self.linked_doc, @block_id)
        return true
      end
    end

  end
end