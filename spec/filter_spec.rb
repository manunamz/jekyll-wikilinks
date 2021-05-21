# # frozen_string_literal: true
# require "jekyll"
# require "jekyll-wikilinks"
# require "spec_helper"

# todo: filter tests
# RSpec.describe(JekyllWikiLinks::BackLinkTypeFilters) do
#   let(:output) do
#     render_liquid(content, { 'backlinks_metadata' => backlinks_metadata })
#   end

#   context "example filter by 'notes' collection type" do
#     let(:backlinks_metadata) { [
#       instance_double("Document", :collection => "notes", :content => "a note"),
#       instance_double("Document", :collection => "posts", :content => "a post"),
#       instance_double("Page", :relative_path => "_pages/a-page.md", :content => "a page"),
#     ] }
#     let(:content)  { "{\% assign note_backlink = #{backlinks_metadata} | backlink_type: \"notes\" \%}{{ note_backlink }}" }

#     it "produces the correct filtered backlinks" do
#       puts output
#       expect(output).to eq(nil)
#     end
#   end
# end
