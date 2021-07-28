# frozen_string_literal: true

require "jekyll-wikilinks"
require "spec_helper"

RSpec.describe(Jekyll::WikiLinks::Generator) do
  include_context "shared jekyll configs"
  let(:config_overrides) { {} }
  let(:site)                            { Jekyll::Site.new(config) }
  
  let(:base_case_a)                     { find_by_title(site.collections["docs"].docs, "Base Case A") }
  let(:base_case_b)                     { find_by_title(site.collections["docs"].docs, "Base Case B") }

  let(:typed_inline)                    { find_by_title(site.collections["docs"].docs, "Typed Link Inline") }
  let(:typed_block)                     { find_by_title(site.collections["docs"].docs, "Typed Link Block") }
  let(:typed_block_many)                { find_by_title(site.collections["docs"].docs, "Typed Link Block Many") }
  
  # makes markdown tests work
  subject { described_class.new(site.config) }

  before(:each) do
    site.reset
    site.process
  end

  after(:each) do
    # cleanup generated assets
    FileUtils.rm_rf(Dir["#{fixtures_dir("/assets/graph-net-web.json")}"])
    # cleanup _site/ dir
    FileUtils.rm_rf(Dir["#{site_dir()}"])
  end

  context "when inline style typed::[[wikilink]] exists" do
    
    it "adds 'backlinks' to linked document" do
      expect(base_case_a.data.keys).to include("backlinks")
    end

    it "'backlinks' has keys 'type' and 'doc', whose values are strings and jekyll docs respectively" do
      backlink_doc = base_case_a.data['backlinks'].select{ |bl| bl['doc']['title'] == "Typed Link Inline" }.first
      expect(backlink_doc['type']).to_not be_nil
      expect(backlink_doc['type']).to be_a(String)
      expect(backlink_doc['type']).to eq("inline-typed")
      expect(backlink_doc['doc']).to eq(typed_inline)
    end

    it "adds 'forelinks' to original document" do
      expect(base_case_a.data.keys).to include("forelinks")
    end

    it "'forelinks' has keys 'type' and 'doc', whose values are strings and jekyll docs respectively" do
      forelink_doc = typed_inline.data['forelinks'].select{ |bl| bl['doc']['title'] == "Base Case A" }.first
      expect(forelink_doc['type']).to_not be_nil
      expect(forelink_doc['type']).to be_a(String)
      expect(forelink_doc['type']).to eq("inline-typed")
      expect(forelink_doc['doc']).to eq(base_case_a)
    end

    it "full html" do
      expect(typed_inline.output).to eq("<p>This link is typed inline: <a class=\"wiki-link link-type inline-typed\" href=\"/doc/8f6277a1-b63a-4ac7-902d-d17e27cb950c/\">base case a</a>.</p>\n")
    end

  end

  context "when block style typed::[[wikilink]] exists" do

    it "adds 'attributed' to linked document" do
      expect(base_case_a.data.keys).to include('attributed')
    end

    it "'attributed' has keys 'type' and 'doc', whose values are strings and jekyll docs respectively" do
      attributed_doc = base_case_a.data['attributed'].select{ |bl| bl['doc']['title'] == "Typed Link Block" }.first
      expect(attributed_doc['type']).to_not be_nil
      expect(attributed_doc['type']).to be_a(String)
      expect(attributed_doc['type']).to eq("block-typed")
      expect(attributed_doc['doc']).to eq(typed_block)
    end

    it "adds 'attributes' to original document" do
      expect(typed_block.data.keys).to include("attributes")
    end

    it "'attributes' has keys 'type' and 'doc', whose values are strings and jekyll docs respectively" do
      attributes_doc = typed_block.data['attributes'].select{ |bl| bl['doc']['title'] == "Base Case A" }.first
      expect(attributes_doc['type']).to_not be_nil
      expect(attributes_doc['type']).to be_a(String)
      expect(attributes_doc['type']).to eq("block-typed")
      expect(attributes_doc['doc']).to eq(base_case_a)
    end

    it "full html" do
      expect(typed_block.output).to eq("<p>This link is block typed.</p>\n\n")
    end

  end

  context "when there are multiple block style typed::[[wikilink]]s" do

    it "adds 'attributed' to linked documents" do
      expect(base_case_a.data.keys).to include('attributed')
      expect(base_case_b.data.keys).to include('attributed')
    end

    it "adds 'attributes' to original document" do
      expect(typed_block_many.data.keys).to include("attributes")
    end

    it "full html" do
      expect(typed_block_many.output).to eq("\n<p>Add multiple block level typed wikilinks to create wikipedia-style infoboxes!</p>\n")
    end

    # first attribute

    it "'attributed' has keys 'type' and 'doc', whose values are strings and jekyll docs respectively" do
      attributed_doc = base_case_a.data['attributed'].select{ |bl| bl['doc']['title'] == "Typed Link Block Many" }.first
      expect(attributed_doc['type']).to_not be_nil
      expect(attributed_doc['type']).to be_a(String)
      expect(attributed_doc['type']).to eq("block-typed")
      expect(attributed_doc['doc']).to eq(typed_block_many)
    end

    it "'attributes' has keys 'type' and 'doc', whose values are strings and jekyll docs respectively" do
      attributes_doc = typed_block_many.data['attributes'].select{ |bl| bl['doc']['title'] == "Base Case A" }.first
      expect(attributes_doc['type']).to_not be_nil
      expect(attributes_doc['type']).to be_a(String)
      expect(attributes_doc['type']).to eq("block-typed")
      expect(attributes_doc['doc']).to eq(base_case_a)
    end

    # second attribute

    it "'attributed' has keys 'type' and 'doc', whose values are strings and jekyll docs respectively" do
      attributed_doc = base_case_b.data['attributed'].select{ |bl| bl['doc']['title'] == "Typed Link Block Many" }.first
      expect(attributed_doc['type']).to_not be_nil
      expect(attributed_doc['type']).to be_a(String)
      expect(attributed_doc['type']).to eq("another-block-typed")
      expect(attributed_doc['doc']).to eq(typed_block_many)
    end

    it "'attributes' has keys 'type' and 'doc', whose values are strings and jekyll docs respectively" do
      attributes_doc = typed_block_many.data['attributes'].select{ |bl| bl['doc']['title'] == "Base Case B" }.first
      expect(attributes_doc['type']).to_not be_nil
      expect(attributes_doc['type']).to be_a(String)
      expect(attributes_doc['type']).to eq("another-block-typed")
      expect(attributes_doc['doc']).to eq(base_case_b)
    end
  end
end