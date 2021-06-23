# TODO: Would be nice to put LinkIndex-related data into real objects as opposed to sticking tons and tons of data into frontmatter...I think...

# modelling off of 'related_posts': https://github.com/jekyll/jekyll/blob/6855200ebda6c0e33f487da69e4e02ec3d8286b7/lib/jekyll/document.rb#L402
# module LinkLogic
#   attr_accessor :attributed, :attributes, :backlinks, :forelinks

#   # 'links' 'type' is 'nil' for untyped links.
#   # 'attributes' are block-level typed forelinks; their 'type' may not be 'nil'.
#   # 'attributed' are block-level typed backlinks; their 'type' may not be 'nil'.
#   # [{ 'type': str, 'doc': doc }, ...]
# end

# module Jekyll
#   class Page
#     # it would be nice if these would only exist if the page is guaranteed to be a markdown file.
#     include LinkLogic
#   end
# end

# module Jekyll
#   class Document
#     include LinkLogic
#   end
# end
