# frozen_string_literal: true

require "jekyll-wikilinks"
require "spec_helper"
require "shared_context"

RSpec.describe(Jekyll::WikiLinks::Generator) do
  include_context "shared jekyll configs"

  let(:config_overrides)              { { "collections" => { "untyped" => { "output" => true }, "target" => { "output" => true } } } }
  let(:site)                          { Jekyll::Site.new(config) }


  # links
  let(:untyped_link)                  { find_by_title(site.collections["untyped"].docs, "Untyped Link") }
  let(:untyped_link_missing_doc)      { find_by_title(site.collections["untyped"].docs, "Untyped Link Missing Doc") }
  let(:untyped_link_whitespace)       { find_by_title(site.collections["untyped"].docs, "Untyped Link Whitespace In Filename") }
  let(:untyped_link_lvl_header)       { find_by_title(site.collections["untyped"].docs, "Untyped Link Header") }
  let(:untyped_link_lvl_block)        { find_by_title(site.collections["untyped"].docs, "Untyped Link Block") }
  let(:untyped_link_page)             { find_by_title(site.collections["untyped"].docs, "Untyped Link Page") }
  let(:untyped_link_post)             { find_by_title(site.collections["untyped"].docs, "Untyped Link Post") }
  # targets
  let(:untyped_a)                     { find_by_title(site.collections["target"].docs, "Untyped A") }
  let(:untyped_b)                     { find_by_title(site.collections["target"].docs, "Untyped B") }
  let(:whitespace_in_filename)        { find_by_title(site.collections["target"].docs, "Whitespace In Filename") }
  let(:w_header)                      { find_by_title(site.collections["target"].docs, "Level Header") }
  let(:w_block)                       { find_by_title(site.collections["target"].docs, "Level Block") }
  let(:one_page)                      { find_by_title(site.pages, "One Page") }
  let(:one_post)                      { find_by_title(site.collections["posts"].docs, "One Post") }
  let(:web_link)                      { find_by_title(site.collections["target"].docs, "Web Link") }
  let(:untyped_w_html)                { find_by_title(site.collections["target"].docs, "With HTML") }

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

  context "UNTYPED [[wikilinks]]" do

    context "when target doc exists" do

      context "html output" do

        it "full" do
          expect(untyped_link.output).to eq("<p>This doc contains a wikilink to <a class=\"wiki-link\" href=\"/target/untyped.a/\">untyped a</a>.</p>\n")
          expect(untyped_a.output).to eq("\n")
        end

        it "injects a element" do
          expect(untyped_link.output).to include("<a")
          expect(untyped_link.output).to include("</a>")
        end

        it "assigns 'wiki-link' class to a element" do
          expect(untyped_link.output).to include("class=\"wiki-link\"")
        end

        it "assigns 'a' tag's 'href' to document url" do
          expect(untyped_link.output).to include("href=\"/target/untyped.a/\"")
        end

        it "generates a clean url when configs assign 'permalink' to 'pretty'" do
          expect(untyped_link.output).to_not include(".html")
        end

        it "downcases title in wikilink's rendered text" do
          expect(untyped_link.output).to include(untyped_a.data['title'].downcase)
        end

      end

      context "metadata:" do

        context "'attributed'" do

          it "not added to document" do
            expect(untyped_link.data['attributed']).to eq([])
          end

          it "not added to document" do
            expect(untyped_a.data['attributed']).to eq([])
          end

        end

        context "'attributes'" do

          it "not added to document" do
            expect(untyped_link.data['attributes']).to eq([])
          end

          it "not added to linked document" do
            expect(untyped_a.data['attributes']).to eq([])
          end

        end

        context "'backlinks'" do

          it "not added to original document" do
            expect(untyped_link.data['backlinks']).to eq([])
          end

          it "is added to linked document" do
            expect(untyped_a.data['backlinks']).to_not eq([])
          end

          it "contain array of hashes with keys 'type' and 'url'" do
            expect(untyped_a.data['backlinks']).to be_a(Array)
            expect(untyped_a.data['backlinks'][0].keys).to eq([ "type", "url" ])
          end

        end

        context "'forelinks'" do

          it "is added to document" do
            expect(untyped_link.data['forelinks']).to_not eq([])
          end

          it "contain array of hashes with keys 'type' and 'url'" do
            expect(untyped_link.data['forelinks']).to be_a(Array)
            expect(untyped_link.data['forelinks'][0].keys).to eq([ "type", "url" ])
          end

          it "not added to linked document" do
            expect(untyped_a.data['forelinks']).to eq([])
          end

        end

      end

    end

    context "when target doc does not exist" do

      context "html output" do

        it "full" do
          expect(untyped_link_missing_doc.output).to eq("<p>This doc contains a wikilink to <span title=\"Content not found.\" class=\"invalid-wiki-link\">[[missing.doc]]</span>.</p>\n")
        end

        it "injects a span element with descriptive title" do
          expect(untyped_link_missing_doc.output).to include("<span title=\"Content not found.\"")
          expect(untyped_link_missing_doc.output).to include("</span>")
        end

        it "assigns 'invalid-wiki-link' class to span element" do
          expect(untyped_link_missing_doc.output).to include("class=\"invalid-wiki-link\"")
        end

        it "leaves original angle brackets and text untouched" do
          expect(untyped_link_missing_doc.output).to include("[[missing.doc]]")
        end


        # it "handles header url fragments; full output" do
        #   expect(link_header_missing_doc.output).to eq("<p>This doc contains an invalid link with an invalid header <span title=\"Content not found.\" class=\"invalid-wiki-link\">[[long-doc#Zero]]</span>.</p>\n")
        # end

      end

      context "metadata:" do

        it "'attributed' not added to document" do
          expect(untyped_link_missing_doc.data['attributed']).to eq([])
        end

        it "'attributes' not added to document" do
          expect(untyped_link_missing_doc.data['attributes']).to eq([])
        end

        it "'backlinks' not added to document" do
          expect(untyped_link_missing_doc.data['backlinks']).to eq([])
        end

        it "'forelinks' not added to document" do
          expect(untyped_link_missing_doc.data['forelinks']).to eq([])
        end

      end

    end

    context "work as expected across jekyll doc types" do

      it "post points to collection item; full output" do
        expect(one_post.output).to eq("<p>This is a post.</p>\n")
      end

      it "collection item points to post; full output" do
        expect(untyped_link_post.output).to eq("<p>This doc links to <a class=\"wiki-link\" href=\"/2020/12/08/one-post/\">one post</a>.</p>\n")
      end

      it "page points to collection item; full output" do
        expect(one_page.output).to eq("<p>This is a page.</p>\n")
      end

      it "collection item points to page; full output" do
        expect(untyped_link_page.output).to eq("<p>This doc links to <a class=\"wiki-link\" href=\"/one-page/\">one page</a>.</p>\n")
      end

      # todo: collection-type-1 <-> collection-type-2
      # todo: page <-> post
    end

    context "works with html in markdown file: html output" do

      it "full" do
        expect(untyped_w_html.output).to eq("<p>This doc has some HTML:</p>\n\n<div class=\"box\">\n  And inside is a link: <a class=\"wiki-link\" href=\"/target/untyped.b/\">untyped b</a>.\n</div>\n")
      end

      it "preserves html" do
        expect(untyped_w_html.output).to include("<div class=\"box\">")
        expect(untyped_w_html.output).to include("</div>")
      end

      it "handles wikilinks in html's innertext" do
        expect(untyped_w_html.output).to_not include("[[untyped.b]]")
        expect(untyped_w_html.output).to include("<a class=\"wiki-link\" href=\"/target/untyped.b/\">untyped b</a>")
      end

    end

    context "works with whitespace in filename" do

      it "full" do
        expect(untyped_link_whitespace.output).to eq("<p>Link to <a class=\"wiki-link\" href=\"/target/whitespace%20in%20filename/\">whitespace in filename</a>.</p>\n")
      end

    end

    context "web links (non-wiki-links)" do

      it "have a 'web-link' css class added to their 'a' element" do
        expect(web_link.content).to include("web-link")
      end

      it "full output" do
        expect(web_link.content).to eq("<p>A <a href=\"www.example.com\" class=\"web-link\">web link</a>.</p>\n")
      end

    end

    context "level:" do

      context "header" do

        context "html output" do

          it "full" do
            expect(untyped_link_lvl_header.output).to eq("<p>This doc contains a link to a header <a class=\"wiki-link\" href=\"/target/untyped.lvl.header/#a-header\">level header &gt; A Header</a>.</p>\n")
          end

          it "header url fragments contain doc's filename and header text" do
            expect(untyped_link_lvl_header.output).to include("level header &gt; A Header")
          end

          it "header sluggified and is fragment in url" do
            expect(untyped_link_lvl_header.output).to include("#a-header")
            expect(untyped_link_lvl_header.output).to include("href=\"/target/untyped.lvl.header/#a-header\"")
          end

        end

        context "metadata:" do

          it "'attributed' not added to either document" do
            expect(untyped_link_lvl_header.data['attributed']).to eq([])
            expect(w_header.data['attributed']).to eq([])
          end

          it "'attributes' not added to either document" do
            expect(untyped_link_lvl_header.data['attributes']).to eq([])
            expect(w_header.data['attributes']).to eq([])
          end

          it "'backlinks' not added to either document" do
            expect(untyped_link_lvl_header.data['backlinks']).to eq([])
            expect(w_header.data['attributes']).to eq([])
          end

          it "'forelinks' not added to either document" do
            expect(untyped_link_lvl_header.data['forelinks']).to eq([])
            expect(w_header.data['attributes']).to eq([])
          end

        end

      end

      context "block" do

        context "html output" do

          it "full" do
            expect(untyped_link_lvl_block.output).to eq("<p>This doc contains a link to a block <a class=\"wiki-link\" href=\"/target/untyped.lvl.block/#block_id\">level block &gt; ^block_id</a>.</p>\n")
          end

          it "block url fragments contain doc's filename and block id" do
            expect(untyped_link_lvl_block.output).to include("level block &gt; ^block_id")
          end

          it "block url fragment in url" do
            expect(untyped_link_lvl_block.output).to include("#block_id")
            expect(untyped_link_lvl_block.output).to include("href=\"/target/untyped.lvl.block/#block_id\"")
          end

        end

        context "metadata:" do

          it "'attributed' not added to either document" do
            expect(untyped_link_lvl_block.data['attributed']).to eq([])
            expect(w_block.data['attributed']).to eq([])
          end

          it "'attributes' not added to either document" do
            expect(untyped_link_lvl_block.data['attributes']).to eq([])
            expect(w_block.data['attributes']).to eq([])
          end

          it "'backlinks' not added to either document" do
            expect(untyped_link_lvl_block.data['backlinks']).to eq([])
            expect(w_block.data['attributes']).to eq([])
          end

          it "'forelinks' not added to either document" do
            expect(untyped_link_lvl_block.data['forelinks']).to eq([])
            expect(w_block.data['attributes']).to eq([])
          end

        end

      end

    end

  end

end
