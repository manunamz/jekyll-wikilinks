# modelling off of 'related_posts': https://github.com/jekyll/jekyll/blob/6855200ebda6c0e33f487da69e4e02ec3d8286b7/lib/jekyll/document.rb#L402
module LinkLogic
  attr_accessor :backattrs, :backlinks, :foreattrs, :forelinks

  # 'links' 'type' is 'nil' for untyped links.
  # 'attributes' are built from block-level typed links and their 'type' may not be 'nil'.
  # [{ 'type': str, 'doc': doc }, ...]
end

module Jekyll
  class Page
    # it would be nice if these would only exist if the page is guaranteed to be a markdown file.
    include LinkLogic
  end
end

module Jekyll
  class Document
    include LinkLogic
  end
end
