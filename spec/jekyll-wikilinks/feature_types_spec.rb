# frozen_string_literal: true
require "jekyll"
require "jekyll-wikilinks"
require "spec_helper"

RSpec.describe(JekyllWikiLinks::Generator) do
  let(:config_overrides) { {} }
  let(:config) do
    Jekyll.configuration(
      config_overrides.merge(
        "collections"          => { "docs" => { "output" => true } },
        "permalink"            => "pretty",
        "skip_config_files"    => false,
        "source"               => fixtures_dir,
        "destination"          => site_dir,
        "url"                  => "garden.testsite.com",
        "testing"              => true,
        # "baseurl"              => "",
      )
    )
  end
  let(:site)                            { Jekyll::Site.new(config) }
  
  let(:base_case_a)                     { find_by_title(site.collections["docs"].docs, "Base Case A") }
  let(:base_case_b)                     { find_by_title(site.collections["docs"].docs, "Base Case B") }

  let(:typed_inline)                    { find_by_title(site.collections["docs"].docs, "Typed Link Inline") }
  let(:typed_block)                     { find_by_title(site.collections["docs"].docs, "Typed Link Block") }
  
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
    
    it "adds 'backlinks' to document" do
      expect(base_case_a.data.keys).to include("backlinks")
    end

    it "'backlinks' includes all jekyll types -- pages, docs (posts and collections)" do
      backlink_doc = base_case_a.data['backlinks'].select{ |bl| bl['doc']['title'] == "Typed Link Inline" }.first
      expect(backlink_doc['type']).to_not be_nil
      expect(backlink_doc['type']).to be_a(String)
      expect(backlink_doc['type']).to eq("inline-typed")
      expect(backlink_doc['doc']).to eq(typed_inline)
    end

    it "adds 'forelinks' to document" do
      expect(base_case_a.data.keys).to include("forelinks")
    end

    it "'forelinks' includes all jekyll types -- pages, docs (posts and collections)" do
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

    it "adds 'attributed' to document" do
      expect(base_case_a.data.keys).to include('attributed')
    end

    it "'attributed' includes all jekyll types -- pages, docs (posts and collections)" do
      backattr_doc = base_case_a.data['attributed'].select{ |bl| bl['doc']['title'] == "Typed Link Block" }.first
      expect(backattr_doc['type']).to_not be_nil
      expect(backattr_doc['type']).to be_a(String)
      expect(backattr_doc['type']).to eq("block-typed")
      expect(backattr_doc['doc']).to eq(typed_block)
    end

    it "adds 'attributes' to document" do
      expect(typed_block.data.keys).to include("attributes")
    end

    it "'attributes' includes all jekyll types -- pages, docs (posts and collections)" do
      foreattr_doc = typed_block.data['attributes'].select{ |bl| bl['doc']['title'] == "Base Case A" }.first
      expect(foreattr_doc['type']).to_not be_nil
      expect(foreattr_doc['type']).to be_a(String)
      expect(foreattr_doc['type']).to eq("block-typed")
      expect(foreattr_doc['doc']).to eq(base_case_a)
    end

    it "full html" do
      expect(typed_block.output).to eq("<p>This link is block typed.</p>\n\n")
    end

  end
end