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
  
  # file
  let(:base_case_a)                     { find_by_title(site.collections["docs"].docs, "Base Case A") }
  let(:base_case_b)                     { find_by_title(site.collections["docs"].docs, "Base Case B") }
  let(:one_page)                        { find_by_title(site.pages, "One Page") }
  let(:one_post)                        { find_by_title(site.collections["posts"].docs, "One Post") }
  let(:link_page)                       { find_by_title(site.collections["docs"].docs, "Link Page") }
  let(:link_post)                       { find_by_title(site.collections["docs"].docs, "Link Post") }
  let(:missing_doc)                     { find_by_title(site.collections["docs"].docs, "Missing Doc") }
  let(:missing_doc_many)                { find_by_title(site.collections["docs"].docs, "Missing Doc Many") }
  let(:link_whitespace_in_filename)     { find_by_title(site.collections["docs"].docs, "Link Whitespace In Filename") }
  let(:whitespace_in_filename)          { find_by_title(site.collections["docs"].docs, "Whitespace In Filename") }
  # header link/url fragments
  let(:link_header)                     { find_by_title(site.collections["docs"].docs, "Link Header") }
  let(:link_header_missing_doc)         { find_by_title(site.collections["docs"].docs, "Link Header Missing") }
  # block link
  let(:link_block)                      { find_by_title(site.collections["docs"].docs, "Link Block") }

  # makes markdown tests work
  subject { described_class.new(site.config) }

  before(:each) do
    site.reset
    site.process
  end

  # todo: change to :each
  after(:all) do
    # cleanup generated assets
    FileUtils.rm_rf(Dir["#{fixtures_dir("/assets/graph-net-web.json")}"])
    # cleanup _site/ dir
    FileUtils.rm_rf(Dir["#{site_dir()}"])
  end

  context "when target [[wikilink]] doc exists" do

    it "injects a element" do
      expect(base_case_a.output).to include("<a")
      expect(base_case_a.output).to include("</a>")

      expect(base_case_b.output).to include("<a")
      expect(base_case_b.output).to include("</a>")
    end

    it "assigns 'wiki-link' class to a element" do
      expect(base_case_a.output).to include("class=\"wiki-link\"")
      expect(base_case_b.output).to include("class=\"wiki-link\"")
    end

    it "assigns a element's href to permalink" do
      expect(base_case_a.output).to include("href=\"/doc/e0c824b6-0b8c-4595-8032-b6889edd815f/\"")
      expect(base_case_b.output).to include("href=\"/doc/8f6277a1-b63a-4ac7-902d-d17e27cb950c/\"")
    end

    # todo: add test for '.html' when 'permalink' is not set to 'pretty'
    it "generates a clean url when configs assign 'permalink' to 'pretty'" do
      expect(base_case_a.output).to_not include(".html")
      expect(base_case_b.output).to_not include(".html")
    end

    it "adds 'backattrs' to document" do
      expect(base_case_a.instance_variable_get(:@backattrs)).to_not be_nil
      expect(base_case_a.instance_variable_get(:@backattrs)[0]['type']).to_not be_nil
      expect(base_case_a.instance_variable_get(:@backattrs)[0]['doc']).to_not be_nil
      expect(base_case_b.instance_variable_get(:@backattrs)).to_not be_nil
    end

    it "adds 'backlinks' to document" do
      expect(base_case_a.instance_variable_get(:@backlinks)).to_not be_nil
      expect(base_case_b.instance_variable_get(:@backlinks)).to_not be_nil
    end

    it "'backlinks' includes all jekyll types -- pages, docs (posts and collections)" do
      expect(base_case_a.backlinks[0]['doc']).to be_a(Jekyll::Page)
      expect(base_case_a.backlinks[1]['doc']).to be_a(Jekyll::Document)
      # 'base_case_b' does not include any pages in its backlinks
      # expect(base_case_b.instance_variable_get(:@backlinks)).to include(Jekyll::Page)
      # expect(base_case_b.instance_variable_get(:@backlinks)[2]['doc']).to be_kind_of(Jekyll::Document)
    end
    
    it "adds 'foreattrs' to document" do
      expect(base_case_a.instance_variable_get(:@foreattrs)).to_not be_nil
      expect(base_case_b.instance_variable_get(:@foreattrs)).to_not be_nil
    end

    it "adds 'forelinks' to document" do
      expect(base_case_a.instance_variable_get(:@forelinks)).to_not be_nil
      expect(base_case_b.instance_variable_get(:@forelinks)).to_not be_nil
    end

    it "'forelinks' includes all jekyll types -- pages, docs (posts and collections)" do
      expect(base_case_a.forelinks[0]['doc']).to be_a(Jekyll::Document)
      # 'base_case_b' does not include any pages in its backlinks
      # expect(base_case_b.instance_variable_get(:@forelinks)).to include(Jekyll::Page)
      # expect(base_case_b.instance_variable_get(:@forelinks)[0]['doc']).to include(Jekyll::Document)
    end

    it "full output" do
      expect(base_case_a.output).to eq("<p>This <a class=\"wiki-link\" href=\"/doc/e0c824b6-0b8c-4595-8032-b6889edd815f/\">base case b</a> has a littlecar.</p>\n")
      expect(base_case_b.output).to eq("<p>This <a class=\"wiki-link\" href=\"/doc/8f6277a1-b63a-4ac7-902d-d17e27cb950c/\">base case a</a> has a little star.</p>\n")
    end

    # header fragment

    it "header url fragments contain doc's filename and header text" do
      expect(link_header.output).to include("long doc &gt; Two")
    end

    it "header url fragment in url" do
      expect(link_header.output).to include("/docs/long-doc/#two")
    end

    it "processes header url fragments; full output" do
      expect(link_header.output).to eq("<p>This doc contains a link to a header <a class=\"wiki-link\" href=\"/docs/long-doc/#two\">long doc &gt; Two</a>.</p>\n")
    end

    # block fragment

    it "block url fragments contain doc's filename and block id" do
      expect(link_block.output).to include("long doc &gt; ^block_id")
    end

    it "block url fragment in url" do
      expect(link_block.output).to include("/docs/long-doc/#block_id")
    end

    it "processes block url fragments; full output" do
      expect(link_block.output).to eq("<p>This doc contains a link to a block <a class=\"wiki-link\" href=\"/docs/long-doc/#block_id\">long doc &gt; ^block_id</a>.</p>\n")
    end
  end

  context "when [[wikilink]]s references cross jekyll types (collection item, post, or page)" do

    it "work as expected when post targets collection item; full output" do
      expect(one_post.output).to eq("<p>Posts support links, like to <a class=\"wiki-link\" href=\"/doc/8f6277a1-b63a-4ac7-902d-d17e27cb950c/\">base case a</a>.</p>\n")
    end
    
    it "work as expected when collection item targets a post; full output" do
      expect(link_post.output).to eq("<p>This doc links to <a class=\"wiki-link\" href=\"/2020/12/08/one-post/\">one post</a>.</p>\n")
    end

    it "work as expected when page targets collection item; full output" do
      expect(one_page.output).to eq("<p>This page links to a <a class=\"wiki-link\" href=\"/doc/8f6277a1-b63a-4ac7-902d-d17e27cb950c/\">base case a</a>.</p>\n")
    end
    
    it "work as expected when collection item targets a page; full output" do
      expect(link_page.output).to eq("<p>This doc links to <a class=\"wiki-link\" href=\"/one-page/\">one page</a>.</p>\n")
    end

    # todo: collection-type-1 <-> collection-type-2
    # todo: page <-> post
  end

  context "when target [[wikilink]] doc exists and contains whitespace" do
    
    it "[[wikilinks]] work as expected; full output" do
      expect(link_whitespace_in_filename.output).to eq("<p>Link to <a class=\"wiki-link\" href=\"/doc/fb6bf728-948f-489e-9c9f-bb2b92677192/\">whitespace in filename</a>.</p>\n")
    end

  end

  context "when target [[wikilink]] doc does not exist" do
    
    it "injects a span element with descriptive title" do
      expect(missing_doc.output).to include("<span title=\"Content not found.\"")
      expect(missing_doc.output).to include("</span>")
      expect(missing_doc_many.output).to include("<span title=\"Content not found.\"").twice
      expect(missing_doc_many.output).to include("</span>").twice
    end

    it "assigns 'invalid-wiki-link' class to span element" do
      expect(missing_doc.output).to include("class=\"invalid-wiki-link\"")
      expect(missing_doc_many.output).to include("class=\"invalid-wiki-link\"").twice
    end

    it "leaves original angle brackets and text untouched" do
      expect(missing_doc.output).to include("[[no.doc]]")
      expect(missing_doc_many.output).to include("[[no.doc.1]]")
      expect(missing_doc_many.output).to include("[[no.doc.2]]")
    end

    it "full output" do
      expect(missing_doc.output).to eq("<p>This <span title=\"Content not found.\" class=\"invalid-wiki-link\">[[no.doc]]</span> has no target.</p>\n")
      expect(missing_doc_many.output).to eq("<p>This fish has no targets like <span title=\"Content not found.\" class=\"invalid-wiki-link\">[[no.doc.1]]</span> and <span title=\"Content not found.\" class=\"invalid-wiki-link\">[[no.doc.2]]</span>.</p>\n")
    end

    it "handles header url fragments; full output" do
      expect(link_header_missing_doc.output).to eq("<p>This doc contains an invalid link with an invalid header <span title=\"Content not found.\" class=\"invalid-wiki-link\">[[long-doc#Zero]]</span>.</p>\n")
    end

  end
end