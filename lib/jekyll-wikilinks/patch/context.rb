# frozen_string_literal: true

module Jekyll
  module WikiLinks

    class Context
      attr_reader :site

      def initialize(site)
        @site = site
      end

      def registers
        { :site => site }
      end
    end
    
  end
end
