# frozen_string_literal: true
require "jekyll"

# appending to built-in jekyll site object to pass data to jekyll-d3

module Jekyll

  class Site
    attr_accessor :link_index
  end

end
