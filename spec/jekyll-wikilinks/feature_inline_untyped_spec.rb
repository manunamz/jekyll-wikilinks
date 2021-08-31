# frozen_string_literal: true

require "jekyll-wikilinks"
require "spec_helper"
require "shared_context"

RSpec.describe(Jekyll::WikiLinks::Generator) do
  include_context "shared jekyll configs"

  let(:config_overrides)              { { "collections" => { "untyped" => { "output" => true }, "target" => { "output" => true } } } }
  let(:site)                          { Jekyll::Site.new(config) }

  # links
  let(:link)                          { find_by_title(site.collections["untyped"].docs, "Untyped Link") }
  let(:link_missing_doc)              { find_by_title(site.collections["untyped"].docs, "Untyped Link Missing Doc") }
  let(:link_lvl_header)               { find_by_title(site.collections["untyped"].docs, "Untyped Link Header") }
  let(:link_lvl_block)                { find_by_title(site.collections["untyped"].docs, "Untyped Link Block") }
  let(:link_page)                     { find_by_title(site.collections["untyped"].docs, "Untyped Link Page") }
  let(:link_post)                     { find_by_title(site.collections["untyped"].docs, "Untyped Link Post") }
  let(:link_nested_in_html)           { find_by_title(site.collections["untyped"].docs, "Nested In HTML") }
  let(:link_w_whitespace)             { find_by_title(site.collections["untyped"].docs, "Untyped Link Whitespace In Filename") }
  # targets
  let(:blank_a)                       { find_by_title(site.collections["target"].docs, "Blank A") }
  let(:blank_b)                       { find_by_title(site.collections["target"].docs, "Blank B") }
  let(:one_page)                      { find_by_title(site.pages, "One Page") }
  let(:one_post)                      { find_by_title(site.collections["posts"].docs, "One Post") }
  let(:lvl_block)                     { find_by_title(site.collections["target"].docs, "Level Block") }
  let(:lvl_header)                    { find_by_title(site.collections["target"].docs, "Level Header") }
  let(:w_whitespace_in_filename)      { find_by_title(site.collections["target"].docs, "Whitespace In Filename") }
  let(:w_web_link)                    { find_by_title(site.collections["target"].docs, "Web Link") }

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

  context "INLINE UNTYPED [[wikilinks]]" do

    context "when target doc exists" do

      context "html output" do

        it "full" do
          expect(link.output).to eq("<p>This doc contains a wikilink to <a class=\"wiki-link\" href=\"/target/blank.a/\">blank a</a>.</p>\n")
          expect(blank_a.output).to eq("\n")
        end

        it "injects 'a' tag" do
          expect(link.output).to include("<a")
          expect(link.output).to include("</a>")
        end

        it "assigns 'wiki-link' class to 'a' tag" do
          expect(link.output).to include("class=\"wiki-link\"")
        end

        it "assigns 'a' tag's 'href' to document url" do
          expect(link.output).to include("href=\"/target/blank.a/\"")
        end

        it "generates a clean url when configs assign 'permalink' to 'pretty'" do
          expect(link.output).to_not include(".html")
        end

        it "downcases title in wikilink's rendered text" do
          expect(link.output).to include('>' + blank_a.data['title'].downcase + '<')
        end

      end

      context "metadata:" do

        it "'attributed' not added to either document" do
          expect(link.data['attributed']).to eq([])
          expect(blank_a.data['attributed']).to eq([])
        end

        it "'attributes' not added to either document" do
          expect(link.data['attributes']).to eq([])
          expect(blank_a.data['attributes']).to eq([])
        end

        context "'backlinks'" do

          it "not added to original document" do
            expect(link.data['backlinks']).to eq([])
          end

          it "is added to linked document" do
            expect(blank_a.data['backlinks']).to_not eq([])
          end

          it "contain array of hashes with keys 'type' and 'url'" do
            expect(blank_a.data['backlinks']).to be_a(Array)
            expect(blank_a.data['backlinks'][0].keys).to eq([ "type", "url" ])
          end

          it "'type' is 'nil'" do
            expect(blank_a.data['backlinks'][0]['type']).to be_nil
          end

          it "'url' is a url str" do
            expect(blank_a.data['backlinks'][0]['url']).to eq("/untyped/link/")
          end

        end

        context "'forelinks'" do

          it "is added to document" do
            expect(link.data['forelinks']).to_not eq([])
          end

          it "contain array of hashes with keys 'type' and 'url'" do
            expect(link.data['forelinks']).to be_a(Array)
            expect(link.data['forelinks'][0].keys).to eq([ "type", "url" ])
          end

          it "not added to linked document" do
            expect(blank_a.data['forelinks']).to eq([])
          end

        end

      end

    end

    context "when target doc does not exist" do

      context "html output" do

        it "full" do
          expect(link_missing_doc.output).to eq("<p>This doc contains a wikilink to <span class=\"invalid-wiki-link\">[[missing.doc]]</span>.</p>\n")
        end

        it "injects a span element with descriptive title" do
          expect(link_missing_doc.output).to include("<span ")
          expect(link_missing_doc.output).to include("</span>")
        end

        it "assigns 'invalid-wiki-link' class to span element" do
          expect(link_missing_doc.output).to include("class=\"invalid-wiki-link\"")
        end

        it "leaves original angle brackets and text untouched" do
          expect(link_missing_doc.output).to include("[[missing.doc]]")
        end


        # it "handles header url fragments; full output" do
        #   expect(link_header_missing_doc.output).to eq("<p>This doc contains an invalid link with an invalid header <span class=\"invalid-wiki-link\">[[long-doc#Zero]]</span>.</p>\n")
        # end

      end

      context "metadata:" do

        it "'attributed' not added to document" do
          expect(link_missing_doc.data['attributed']).to eq([])
        end

        it "'attributes' not added to document" do
          expect(link_missing_doc.data['attributes']).to eq([])
        end

        it "'backlinks' not added to document" do
          expect(link_missing_doc.data['backlinks']).to eq([])
        end

        it "'forelinks' not added to document" do
          expect(link_missing_doc.data['forelinks']).to eq([])
        end

      end

    end

    context "some general valid expectations" do

      context "work as expected across jekyll doc types" do

        it "post points to collection item; full output" do
          expect(one_post.output).to eq("<p>This is a post.</p>\n")
        end

        it "collection item points to post; full output" do
          expect(link_post.output).to eq("<p>This doc links to <a class=\"wiki-link\" href=\"/2020/12/08/one-post/\">one post</a>.</p>\n")
        end

        it "page points to collection item; full output" do
          expect(one_page.output).to eq("<p>This is a page.</p>\n")
        end

        it "collection item points to page; full output" do
          expect(link_page.output).to eq("<p>This doc links to <a class=\"wiki-link\" href=\"/one-page/\">one page</a>.</p>\n")
        end

        # todo: collection-type-1 <-> collection-type-2
        # todo: page <-> post
      end

      context "works with html in markdown file: html output" do

        it "full" do
          expect(link_nested_in_html.output).to eq("<p>This doc has some HTML:</p>\n\n<div class=\"box\">\n  And inside is a link: <a class=\"wiki-link\" href=\"/target/blank.b/\">blank b</a>.\n</div>\n")
        end

        it "preserves html" do
          expect(link_nested_in_html.output).to include("<div class=\"box\">")
          expect(link_nested_in_html.output).to include("</div>")
        end

        it "handles wikilinks in html's innertext" do
          expect(link_nested_in_html.output).to_not include("[[blank.b]]")
          expect(link_nested_in_html.output).to include("<a class=\"wiki-link\" href=\"/target/blank.b/\">blank b</a>")
        end

      end

      context "works with whitespace in filename" do

        it "full" do
          expect(link_w_whitespace.output).to eq("<p>Link to <a class=\"wiki-link\" href=\"/target/w.whitespace%20in%20filename/\">whitespace in filename</a>.</p>\n")
        end

      end

    end

    context "web links (non-wiki-links)" do

      it "have a 'web-link' css class added to their 'a' element" do
        expect(w_web_link.content).to include("web-link")
      end

      it "full output" do
        expect(w_web_link.content).to eq("<p>A <a href=\"www.example.com\" class=\"web-link\">web link</a>.</p>\n")
      end

    end

    context "level:" do

      context "#header" do

        context "html output" do

          it "full" do
            expect(link_lvl_header.output).to eq("<p>This doc contains a link to a header <a class=\"wiki-link\" href=\"/target/lvl.header/#a-header\">level header &gt; A Header</a>.</p>\n")
          end

          it "header url fragments contain doc's filename and header text" do
            expect(link_lvl_header.output).to include("level header &gt; A Header")
          end

          it "header sluggified and is fragment in url" do
            expect(link_lvl_header.output).to include("#a-header")
            expect(link_lvl_header.output).to include("href=\"/target/lvl.header/#a-header\"")
          end

        end

        context "metadata:" do

          it "'attributed' not added to either document" do
            expect(link_lvl_header.data['attributed']).to eq([])
            expect(lvl_header.data['attributed']).to eq([])
          end

          it "'attributes' not added to either document" do
            expect(link_lvl_header.data['attributes']).to eq([])
            expect(lvl_header.data['attributes']).to eq([])
          end

          it "'backlinks' not added to original document" do
            expect(link_lvl_header.data['backlinks']).to eq([])
          end

          it "'backlinks' added to linked document" do
            expect(lvl_header.data['backlinks']).to eq([{"type"=>nil, "url"=>"/untyped/link.lvl.header/"}])
          end

          it "'forelinks' added to original document" do
            expect(link_lvl_header.data['forelinks']).to eq([{"type"=>nil, "url"=>"/target/lvl.header/"}])
          end

          it "'forelinks' not added to linked document" do
            expect(lvl_header.data['forelinks']).to eq([])
          end

        end

      end

      context "^block" do

        context "html output" do

          it "full" do
            expect(link_lvl_block.output).to eq("<p>This doc contains a link to a block <a class=\"wiki-link\" href=\"/target/lvl.block/#block_id\">level block &gt; ^block_id</a>.</p>\n")
          end

          it "block url fragments contain doc's filename and block id" do
            expect(link_lvl_block.output).to include("level block &gt; ^block_id")
          end

          it "block url fragment in url" do
            expect(link_lvl_block.output).to include("#block_id")
            expect(link_lvl_block.output).to include("href=\"/target/lvl.block/#block_id\"")
          end

        end

        context "metadata:" do

          it "'attributed' not added to either document" do
            expect(link_lvl_block.data['attributed']).to eq([])
            expect(lvl_block.data['attributed']).to eq([])
          end

          it "'attributes' not added to either document" do
            expect(link_lvl_block.data['attributes']).to eq([])
            expect(lvl_block.data['attributes']).to eq([])
          end

          it "'backlinks' not added to original document" do
            expect(link_lvl_block.data['backlinks']).to eq([])
          end

          it "'backlinks' added to linked document" do
            expect(lvl_block.data['backlinks']).to eq([{"type"=>nil, "url"=>"/untyped/link.lvl.block/"}])
          end

          it "'forelinks' added to original document" do
            expect(link_lvl_block.data['forelinks']).to eq([{"type"=>nil, "url"=>"/target/lvl.block/"}])
          end

          it "'forelinks' not added to linked document" do
            expect(lvl_block.data['forelinks']).to eq([])
          end

        end

      end

    end

  end

end
