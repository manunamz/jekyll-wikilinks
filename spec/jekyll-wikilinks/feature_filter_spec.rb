# frozen_string_literal: true

require "jekyll-wikilinks"
require "spec_helper"
require "shared_context"

RSpec.describe(Jekyll::WikiLinks::TypeFilters) do
  let(:doc)        { instance_double("Document", :collection => "docs", :content => "a document", :title=> "A Document") }
  let(:post)       { instance_double("Document", :collection => "posts", :content => "a post", :title=>"A Post") }
  let(:page)       { instance_double("Page", :relative_path => "_pages/a-page.md", :content => "a page", :title=>"A Page") }
  let(:mock_links) { [{ :doc => doc }, { :doc => post }, { :doc => page }] }
  # let(:mock_links) { [doc, post, page] }

  # let(:filtered_by_doc_type)  {  }
  # let(:filtered_by_link_type) {  }

  context "filter by 'doc_type'" do
    let(:content)    { '{% assign note_links = mock_links | doc_type: "docs" %}{% for link in note_links %}{{ link.doc.title }}{% endfor %}' }
    let(:output) do
      render_liquid(content, { 'mock_links' => mock_links })
    end

    it "filters links by jekyll doc type" do
      pending("figure out how to test liquid template filters")
      # expect(output).to eq([{ :doc => doc }])
      expect(1).to eq(2)
    end
  end

  context "filter by 'link_type'" do

    it "filters links by 'link_type'" do
      pending("figure out how to test liquid template filters")
      expect(1).to eq(2)
    end

  end
end
