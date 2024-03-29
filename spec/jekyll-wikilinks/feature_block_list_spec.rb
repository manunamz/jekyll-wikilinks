# frozen_string_literal: true

require "jekyll-wikilinks"
require "spec_helper"
require "shared_context"

RSpec.describe(Jekyll::WikiLinks::Generator) do
  include_context "shared jekyll configs"

  let(:config_overrides)              { { "collections" => { "block_list" => { "output" => true }, "target" => { "output" => true } } } }
  let(:site)                          { Jekyll::Site.new(config) }

  # TODO: test whitespace
  # links
  let(:link_comma)                    { find_by_title(site.collections["block_list"].docs, "Block List Link Comma") }
  let(:link_comma_w_whitespace)       { find_by_title(site.collections["block_list"].docs, "Block List Link Comma With Whitespace") }
  let(:link_md_dash)                  { find_by_title(site.collections["block_list"].docs, "Block List Link Markdown Dash") }
  let(:link_md_dash_w_whitespace)     { find_by_title(site.collections["block_list"].docs, "Block List Link Markdown Dash With Whitespace") }
  let(:link_md_star)                  { find_by_title(site.collections["block_list"].docs, "Block List Link Markdown Star") }
  let(:link_md_plus)                  { find_by_title(site.collections["block_list"].docs, "Block List Link Markdown Plus") }
  let(:link_comma_missing_docs)       { find_by_title(site.collections["block_list"].docs, "Block List Link Comma Missing Docs") }
  let(:link_partial_list)             { find_by_title(site.collections["block_list"].docs, "Block List Partial Link") }
  # targets
  let(:blank_a)                       { find_by_title(site.collections["target"].docs, "Blank A") }
  let(:blank_b)                       { find_by_title(site.collections["target"].docs, "Blank B") }

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

  context "BLOCK LIST [[wikilinks]]" do

    context "separated by commas" do

      context "when target docs exist" do

        it "links are removed from html output" do
          expect(link_comma.output).to_not include("block-list::[[blank.a]],[[blank.b]]")
          expect(link_comma.output).to eq("<p>This doc contains a wikilink to a block list…</p>\n\n<p>…link.</p>\n")
        end

        context "metadata:" do

          context "'attributed'" do

            it "not added to document" do
              expect(link_comma.data['attributed']).to eq([])
            end

            it "added to linked document" do
              expect(blank_a.data['attributed']).to_not eq([])
              expect(blank_b.data['attributed']).to_not eq([])
            end

            it "contains array of hashes with keys 'type' and 'urls'" do
              expect(blank_a.data['attributed']).to be_a(Array)
              expect(blank_a.data['attributed'][0].keys).to eq([ "type", "urls" ])
              expect(blank_b.data['attributed']).to be_a(Array)
              expect(blank_b.data['attributed'][0].keys).to eq([ "type", "urls" ])
            end

            it "'type' is the type:: text" do
              expect(blank_a.data['attributed'][0]['type']).to eq("block-list")
              expect(blank_b.data['attributed'][0]['type']).to eq("block-list")
            end

            it "'urls' is an array" do
              expect(blank_a.data['attributed'][0]['urls']).to be_a(Array)
              expect(blank_b.data['attributed'][0]['urls']).to be_a(Array)
            end

            it "'urls' in linked documents contain original document url" do
              expect(blank_a.data['attributed'][0]['urls']).to include("/block_list/link.comma/")
              expect(blank_b.data['attributed'][0]['urls']).to include("/block_list/link.comma/")
            end

          end

          context "'attributes'" do

            it "added to original document" do
              expect(link_comma.data.keys).to include("attributes")
            end

            it "full" do
              expect(link_comma.data['attributes']).to eq([
                {"type"=>"block-list", "urls"=>["/target/blank.a/", "/target/blank.b/"]}
              ])
            end

            it "contain array of hashes with keys 'type' and 'urls'" do
              expect(link_comma.data['attributes']).to be_a(Array)
              expect(link_comma.data['attributes'][0].keys).to eq([ "type", "urls" ])
            end

            it "'type' is the type:: text" do
              expect(link_comma.data['attributes'][0]['type']).to eq("block-list")
            end

            it "'urls' is an array" do
              expect(link_comma.data['attributes'][0]['urls']).to be_a(Array)
            end

            it "'urls' in original document contain linked document urls" do
              expect(link_comma.data['attributes'][0]['urls']).to eq(["/target/blank.a/", "/target/blank.b/"])
            end

            it "not added to linked document" do
              expect(blank_a.data['attributes']).to eq([])
              expect(blank_b.data['attributes']).to eq([])
            end

          end

          it "'backlinks' not added to any document" do
            expect(link_comma.data['backlinks']).to eq([])
            expect(blank_a.data['backlinks']).to eq([])
            expect(blank_b.data['backlinks']).to eq([])
          end

          it "'forelinks' not added to any document" do
            expect(link_comma.data['forelinks']).to eq([])
            expect(blank_a.data['forelinks']).to eq([])
            expect(blank_b.data['forelinks']).to eq([])
          end

        end

      end

      context "when target docs do not exist" do

        context "html output" do
  
          it "full" do
            expect(link_comma_missing_docs.output).to eq("<p>This doc contains a wikilink to a block list…</p>\n\n<p>…link.</p>\n")
          end
  
          it "full output contains '…'" do
            expect(link_comma_missing_docs.output).to include("…")
          end
  
          it "does not inject a span element with descriptive title" do
            expect(link_comma_missing_docs.output).to_not include("<span ")
            expect(link_comma_missing_docs.output).to_not include("</span>")
          end
  
          it "does not assign 'invalid-wiki-link' class to span element" do
            expect(link_comma_missing_docs.output).to_not include("class=\"invalid-wiki-link\"")
          end
  
          it "removes original angle brackets and wikitext" do
            expect(link_comma_missing_docs.output).to_not include("block-list::[[blank.a]],[[missing.doc]]")
          end
  
          # it "handles header url fragments; full output" do
          #   expect(link_header_missing_doc.output).to eq("<p>This doc contains an invalid link with an invalid header <span class=\"invalid-wiki-link\">[[long-doc#Zero]]</span>.</p>\n")
          # end
  
        end
  
        context "metadata:" do
  
          it "'missing' added to document" do
            expect(link_comma_missing_docs.data['missing']).to eq(["missing.doc", "another.missing.doc"])
          end

          it "'attributed' not added to original document" do
            expect(link_comma_missing_docs.data['attributed']).to eq([])
          end
  
          it "'attributed' added to linked document in existing files" do
            expect(blank_a.data['attributed']).to include({"type"=>"block-list-partial", "urls"=>["/block_list/link.partial/"]})
          end
  
          it "'attributes' not added to document" do
            expect(link_comma_missing_docs.data['attributes']).to eq([])
          end
  
          it "'backlinks' not added to document" do
            expect(link_comma_missing_docs.data['backlinks']).to eq([])
          end
  
          it "'forelinks' not added to document" do
            expect(link_comma_missing_docs.data['forelinks']).to eq([])
          end
  
        end
  
      end

      context "when some target docs exist" do

        it "links are removed from html output" do
          expect(link_partial_list.output).to_not include("block-list::[[blank.a]],[[missing.doc]]")
          expect(link_partial_list.output).to eq("<p>This doc contains a wikilink to a block list link…</p>\n\n<p>…with some files missing.</p>\n")
        end

        context "metadata:" do

          it "'missing' added to document" do
            expect(link_partial_list.data['missing']).to eq(["missing.doc"])
          end

          context "'attributed'" do

            it "not added to document" do
              expect(link_partial_list.data['attributed']).to eq([])
            end

            it "added to linked document" do
              expect(blank_a.data['attributed']).to_not eq([])
            end

            it "contains array of hashes with keys 'type' and 'urls'" do
              expect(blank_a.data['attributed']).to be_a(Array)
              expect(blank_a.data['attributed'][0].keys).to eq([ "type", "urls" ])
            end

            it "'type' is the type:: text" do
              expect(blank_a.data['attributed'][0]['type']).to eq("block-list")
            end

            it "'urls' is an array" do
              expect(blank_a.data['attributed'][0]['urls']).to be_a(Array)
            end

            it "'urls' in linked documents contain original document url" do
              expect(blank_a.data['attributed'][1]['urls']).to include("/block_list/link.partial/")
            end

          end

          context "'attributes'" do

            it "added to original document" do
              expect(link_partial_list.data.keys).to include("attributes")
            end

            it "full" do
              expect(link_partial_list.data['attributes']).to eq([
                {"type"=>"block-list-partial", "urls"=>["/target/blank.a/"]}
              ])
            end

            it "contain array of hashes with keys 'type' and 'urls'" do
              expect(link_partial_list.data['attributes']).to be_a(Array)
              expect(link_partial_list.data['attributes'][0].keys).to eq([ "type", "urls" ])
            end

            it "'type' is the type:: text" do
              expect(link_partial_list.data['attributes'][0]['type']).to eq("block-list-partial")
            end

            it "'urls' is an array" do
              expect(link_partial_list.data['attributes'][0]['urls']).to be_a(Array)
            end

            it "'urls' in original document contain linked document urls" do
              expect(link_partial_list.data['attributes'][0]['urls']).to eq(["/target/blank.a/"])
            end

            it "not added to linked document" do
              expect(blank_a.data['attributes']).to eq([])
            end

          end

          it "'backlinks' not added to any document" do
            expect(link_partial_list.data['backlinks']).to eq([])
            expect(blank_a.data['backlinks']).to eq([])
          end

          it "'forelinks' not added to any document" do
            expect(link_partial_list.data['forelinks']).to eq([])
            expect(blank_a.data['forelinks']).to eq([])
          end

        end

      end      

    end

    context "separated by markdown list format" do

      context "when target doc exists" do

        it "links are removed from html output" do
          expect(link_md_dash.output).to_not include("block-list::\n- [[blank.a]]\n- [[blank.b]]\n")
          expect(link_md_dash.output).to eq("<p>This doc contains a wikilink to a block list…</p>\n\n<p>…link.</p>\n")
        end

        context "metadata:" do

          context "'attributed'" do

            it "not added to document" do
              expect(link_md_dash.data['attributed']).to eq([])
            end

            it "added to linked document" do
              expect(blank_a.data.keys).to include('attributed')

              expect(blank_b.data.keys).to include('attributed')
            end

            it "contains array of hashes with keys 'type' and 'urls'" do
              expect(blank_a.data['attributed']).to be_a(Array)
              expect(blank_a.data['attributed'][0].keys).to eq([ "type", "urls" ])

              expect(blank_b.data['attributed']).to be_a(Array)
              expect(blank_b.data['attributed'][0].keys).to eq([ "type", "urls" ])
            end

            it "'type' is the type:: text" do
              expect(blank_a.data['attributed'][0]['type']).to eq("block-list")

              expect(blank_b.data['attributed'][0]['type']).to eq("block-list")
            end

            it "'urls' is an array of url strs" do
              expect(blank_a.data['attributed'][0]['urls']).to be_a(Array)
              expect(blank_a.data['attributed'][0]['urls']).to include("/block_list/link.md.dash/")

              expect(blank_b.data['attributed'][0]['urls']).to be_a(Array)
              expect(blank_b.data['attributed'][0]['urls']).to include("/block_list/link.md.dash/")
            end

          end

          context "'attributes'" do

            it "added to original document" do
              expect(link_md_dash.data.keys).to include("attributes")
            end

            it "full" do
              expect(link_md_dash.data['attributes']).to eq([
                {"type"=>"block-list", "urls"=>["/target/blank.a/", "/target/blank.b/"]}
              ])
            end

            it "contain array of hashes with keys 'type' and 'urls'" do
              expect(link_md_dash.data['attributes']).to be_a(Array)
              expect(link_md_dash.data['attributes'][0].keys).to eq([ "type", "urls" ])
            end

            it "'type' is the type:: text" do
              expect(link_md_dash.data['attributes'][0]['type']).to eq("block-list")
            end

            it "'urls' is a url str" do
              expect(link_md_dash.data['attributes'][0]['urls']).to eq(["/target/blank.a/", "/target/blank.b/"])
            end

            it "not added to linked document" do
              expect(blank_a.data['attributes']).to eq([])
              expect(blank_b.data['attributes']).to eq([])
            end

          end

          it "'backlinks' not added to document" do
            expect(link_md_dash.data['backlinks']).to eq([])
          end

          it "'forelinks' not added to document" do
            expect(link_md_dash.data['forelinks']).to eq([])
          end

        end

        it "accepts any bullet type (-*+)" do
          expect(link_md_dash.data.keys).to include("attributes")
          expect(link_md_star.data.keys).to include("attributes")
          expect(link_md_plus.data.keys).to include("attributes")
        end

      end

    end

  end

  it "'attributed' for block list tests in full" do
    expect(blank_a.data['attributed']).to eq([
      {"type"=>"block-list",
       "urls"=>[
         "/block_list/link.comma/",
         "/block_list/link.comma.w-whitespace/",
         "/block_list/link.md.dash/",
         "/block_list/link.md.dash.w-whitespace/",
         "/block_list/link.md.plus/",
         "/block_list/link.md.star/"
         ]
       },
       # todo: 'block-list-partial' -> 'block-list'
       {"type"=>"block-list-partial", "urls"=>["/block_list/link.partial/"]},
     ])
    expect(blank_b.data['attributed']).to eq([
      {"type"=>"block-list",
       "urls"=>[
         "/block_list/link.comma/",
         "/block_list/link.comma.w-whitespace/",
         "/block_list/link.md.dash/",
         "/block_list/link.md.dash.w-whitespace/",
         "/block_list/link.md.plus/",
         "/block_list/link.md.star/"
         ]
       }
     ])
  end

end
