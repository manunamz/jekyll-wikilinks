# frozen_string_literal: true
require "jekyll"

# appending to built-in jekyll site object to pass data to jekyll-graph

module Jekyll

  class Site
    attr_accessor :doc_mngr, :link_index, :wiki_parser
  end

end
