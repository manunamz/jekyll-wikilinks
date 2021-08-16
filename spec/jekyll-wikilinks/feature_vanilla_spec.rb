# frozen_string_literal: true

require "jekyll-wikilinks"
require "spec_helper"
require "shared_context"

RSpec.describe(Jekyll::WikiLinks::Generator) do
  include_context "shared jekyll configs"
  let(:config_overrides) { {} }
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
  let(:with_html)                       { find_by_title(site.collections["docs"].docs, "With HTML") }
  # header link/url fragments
  let(:link_header)                     { find_by_title(site.collections["docs"].docs, "Link Header") }
  let(:link_header_missing_doc)         { find_by_title(site.collections["docs"].docs, "Link Header Missing") }
  let(:link_header_whitespace)          { find_by_title(site.collections["docs"].docs, "Link Header Whitespace") }
  # block link
  let(:link_block)                      { find_by_title(site.collections["docs"].docs, "Link Block") }

  # makes markdown tests work
  subject { described_class.new(site.config) }

  before(:each) do
    site.reset
    site.process
  end

  after(:each) do
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

    it "assigns a element's href to document url" do
      expect(base_case_a.output).to include("href=\"/doc/e0c824b6-0b8c-4595-8032-b6889edd815f/\"")
      expect(base_case_b.output).to include("href=\"/doc/8f6277a1-b63a-4ac7-902d-d17e27cb950c/\"")
    end

    # todo: add test for '.html' when 'permalink' is not set to 'pretty'
    it "generates a clean url when configs assign 'permalink' to 'pretty'" do
      expect(base_case_a.output).to_not include(".html")
      expect(base_case_b.output).to_not include(".html")
    end

    it "downcases title in wikilink's rendered text" do
      expect(base_case_b.output).to include(base_case_a.data['title'].downcase)
    end

    context "metadata:" do

      context "'attributed'" do

        it "is added to document" do
          expect(base_case_a.data['attributed']).to_not be_nil
          expect(base_case_b.data['attributed']).to_not be_nil
        end

        it "is an array of hashes with keys 'type' and 'doc_url'" do
          expect(base_case_a.data['attributed']).to be_a(Array)
          expect(base_case_a.data['attributed'][0].keys).to eq([ "type", "doc_url" ])

          expect(base_case_b.data['attributed']).to be_a(Array)
          expect(base_case_b.data['attributed'][0].keys).to eq([ "type", "doc_url" ])
        end

        it "full contents" do
          expect(base_case_a.data['attributed']).to eq([
            {"doc_url"=>"/docs/typed.block.many/", "type"=>"many-block-typed"},
            {"doc_url"=>"/docs/typed.block/", "type"=>"block-typed"}
          ])
          expect(base_case_b.data['attributed']).to eq([
            {"doc_url"=>"/docs/typed.block.many/", "type"=>"many-block-typed"}
          ])
        end

      end


      context "'attributes'" do

        it "added to document" do
          expect(base_case_a.data['attributes']).to_not be_nil
          expect(base_case_b.data['attributes']).to_not be_nil
        end

        # 'attributes' is empty in this example -- see feature_types_spec.rb for more robust testing
        it "is an array of hashes (with with keys 'type' and 'doc_url')" do
          expect(base_case_a.data['attributes']).to be_a(Array)
          # expect(base_case_a.data['attributes'][0].keys).to eq([ "type", "doc_url" ])
          expect(base_case_a.data['attributes']).to eq([])

          expect(base_case_b.data['attributes']).to be_a(Array)
          # expect(base_case_b.data['attributes'][0].keys).to eq([ "type", "doc_url" ])
          expect(base_case_b.data['attributes']).to eq([])
        end

      end

      context "'backlinks'" do

        it "added to document" do
          expect(base_case_a.data['backlinks']).to_not be_nil
          expect(base_case_b.data['backlinks']).to_not be_nil
        end

        it "'backlinks' contain array of hashes with keys 'type' and 'doc_url'" do
          expect(base_case_a.data['backlinks']).to be_a(Array)
          expect(base_case_a.data['backlinks'][0].keys).to eq([ "type", "doc_url" ])

          expect(base_case_b.data['backlinks']).to be_a(Array)
          expect(base_case_b.data['backlinks'][0].keys).to eq([ "type", "doc_url" ])
        end

        it "full contents" do
          expect(base_case_a.data['backlinks']).to eq([
            {"doc_url"=>"/one-page/", "type"=>nil},
            {"doc_url"=>"/2020/12/08/one-post/", "type"=>nil},
            {"doc_url"=>"/doc/e0c824b6-0b8c-4595-8032-b6889edd815f/", "type"=>nil},
            {"doc_url"=>"/doc/2849a030-c72d-4a9f-9d1e-9e9a18449e04/", "type"=>nil},
            {"doc_url"=>"/doc/c7317432-6211-49fa-bc0d-7322ad6eecd4/", "type"=>nil},
            {"doc_url"=>"/docs/typed.inline/", "type"=>"inline-typed"},
            {"doc_url"=>"/docs/with-html/", "type"=>nil}
          ])
          expect(base_case_b.data['backlinks']).to eq([
            {"doc_url"=>"/doc/8f6277a1-b63a-4ac7-902d-d17e27cb950c/", "type"=>nil},
            {"doc_url"=>"/docs/embed/", "type"=>nil}
          ])
        end

      end

      context "'forelinks'" do

        it "added to document" do
          expect(base_case_a.data['forelinks']).to_not be_nil
          expect(base_case_b.data['forelinks']).to_not be_nil
        end

        it "contains array of hashes with keys 'type' and 'doc_url'" do
          expect(base_case_a.data['forelinks']).to be_a(Array)
          expect(base_case_a.data['forelinks'][0].keys).to eq([ "type", "doc_url" ])

          expect(base_case_b.data['forelinks']).to be_a(Array)
          expect(base_case_b.data['forelinks'][0].keys).to eq([ "type", "doc_url" ])
        end

        it "full contents" do
          expect(base_case_a.data['forelinks']).to eq([
            {"doc_url"=>"/doc/e0c824b6-0b8c-4595-8032-b6889edd815f/", "type"=>nil}
          ])
          expect(base_case_b.data['forelinks']).to eq([
            {"doc_url"=>"/doc/8f6277a1-b63a-4ac7-902d-d17e27cb950c/", "type"=>nil}
          ])
        end

      end

    end

    # full

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

  context "work as expected when [[wikilink]]s references cross jekyll types..." do

    it "post points to collection item; full output" do
      expect(one_post.output).to eq("<p>Posts support links, like to <a class=\"wiki-link\" href=\"/doc/8f6277a1-b63a-4ac7-902d-d17e27cb950c/\">base case a</a>.</p>\n")
    end

    it "collection item points to post; full output" do
      expect(link_post.output).to eq("<p>This doc links to <a class=\"wiki-link\" href=\"/2020/12/08/one-post/\">one post</a>.</p>\n")
    end

    it "page points to collection item; full output" do
      expect(one_page.output).to eq("<p>This page links to a <a class=\"wiki-link\" href=\"/doc/8f6277a1-b63a-4ac7-902d-d17e27cb950c/\">base case a</a>.</p>\n")
    end

    it "collection item points to page; full output" do
      expect(link_page.output).to eq("<p>This doc links to <a class=\"wiki-link\" href=\"/one-page/\">one page</a>.</p>\n")
    end

    # todo: collection-type-1 <-> collection-type-2
    # todo: page <-> post
  end

  context "with regard to whitespace" do

    it "wikilinked filenames may contain whitespace; full output" do
      expect(link_whitespace_in_filename.output).to eq("<p>Link to <a class=\"wiki-link\" href=\"/doc/fb6bf728-948f-489e-9c9f-bb2b92677192/\">whitespace in filename</a>.</p>\n")
    end

    it "header text containing whitespace is sluggified for url fragments" do
      expect(link_header_whitespace.output).to include("href=\"/docs/long-doc/#a-long-document\"")
    end

    it "header text containing whitespace; full output" do
      expect(link_header_whitespace.output).to eq("<p>This doc contains a link to a header <a class=\"wiki-link\" href=\"/docs/long-doc/#a-long-document\">long doc &gt; A Long Document</a>.</p>\n")
    end

  end

  context "markdown file contains html" do

    it "preserves html" do
      expect(with_html.output).to include("<div class=\"box\">")
      expect(with_html.output).to include("</div>")
    end

    it "handles wikilinks in html's innertext" do
      expect(with_html.output).to_not include("[[base-case.a]]")
      expect(with_html.output).to include("<a class=\"wiki-link\" href=\"/doc/8f6277a1-b63a-4ac7-902d-d17e27cb950c/\">base case a</a>")
    end

    it "full output" do
      expect(with_html.output).to eq("<p>This doc has some HTML:</p>\n\n<div class=\"box\">\n  And inside is a link: <a class=\"wiki-link\" href=\"/doc/8f6277a1-b63a-4ac7-902d-d17e27cb950c/\">base case a</a>.\n</div>\n")
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
