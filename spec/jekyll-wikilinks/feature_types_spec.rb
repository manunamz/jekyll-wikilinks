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
      expect(base_case_a.data['backlinks'][5]['type']).to_not be_nil
      expect(base_case_a.data['backlinks'][5]['type']).to be_a(String)
      expect(base_case_a.data['backlinks'][5]['doc']).to eq(typed_inline)
    end

    it "adds 'forelinks' to document" do
      expect(base_case_a.data.keys).to include("forelinks")
    end

    it "'forelinks' includes all jekyll types -- pages, docs (posts and collections)" do
      expect(typed_inline.data['forelinks'][0]['type']).to_not be_nil
      expect(typed_inline.data['forelinks'][0]['type']).to be_a(String)
      expect(typed_inline.data['forelinks'][0]['doc']).to eq(base_case_a)
    end

    it "full html" do
      expect(typed_inline.output).to eq("<p>This link is typed inline: <a class=\"wiki-link link-type inline-typed\" href=\"/doc/8f6277a1-b63a-4ac7-902d-d17e27cb950c/\">base case a</a>.</p>\n")
    end

  end

  context "when block style typed::[[wikilink]] exists" do

    it "adds 'backattrs' to document" do
      expect(base_case_a.data.keys).to include('backattrs')
    end

    it "'backattrs' includes all jekyll types -- pages, docs (posts and collections)" do
      expect(base_case_a.data['backattrs'][0]['type']).to_not be_nil
      expect(base_case_a.data['backattrs'][0]['type']).to be_a(String)
      expect(base_case_a.data['backattrs'][0]['doc']).to eq(typed_block)
    end

    it "adds 'foreattrs' to document" do
      expect(typed_block.data.keys).to include("foreattrs")
    end

    it "'foreattrs' includes all jekyll types -- pages, docs (posts and collections)" do
      expect(typed_block.data['foreattrs'][0]['type']).to_not be_nil
      expect(typed_block.data['foreattrs'][0]['type']).to be_a(String)
      expect(typed_block.data['foreattrs'][0]['doc']).to eq(base_case_a)
    end

    it "full html" do
      expect(typed_block.output).to eq("<p>This link is block typed.</p>\n\n")
    end

  end
end