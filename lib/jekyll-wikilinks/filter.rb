# frozen_string_literal: true
require "jekyll"

module Jekyll
  module BackLinkTypeFilters
    # usage:
    # {% assign note_backlinks = page.backlinks | backlink_type = "notes" %}
    def backlink_type(backlinks, type)
      return if backlinks.nil?
      target_backlinks = []
      backlinks.each do |bl|
        target_backlinks << bl if self.to_string(bl.type) == type
      end
      return target_backlinks
    end

    def to_string(type)
      return type if type.is_a?(String)
      type = type.to_s
      begin
        String(type)
      rescue ::ArgumentError
        raise ArgumentError, "invalid type"
      end
    end
  end
end

Liquid::Template.register_filter(Jekyll::BackLinkTypeFilters)
