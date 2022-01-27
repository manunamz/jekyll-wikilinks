# frozen_string_literal: true

require "jekyll-wikilinks"
require "spec_helper"
require "shared_context"

RSpec.describe(Jekyll::WikiLinks::Generator) do
  include_context "shared jekyll configs"

  let(:config_overrides)                { { 
    "collections" => { 
      "file_path" => { "output" => true }, 
      "target" => { "output" => true },
    }, 
  } }
  let(:site)                            { Jekyll::Site.new(config) }

  # links
  let(:link_absolute)                   { find_by_title(site.collections["file_path"].docs, "Absolute File Path Link") }
  let(:link_absolute_nested)            { find_by_title(site.collections["file_path"].docs, "Nested Absolute File Path Link") }
  # todo: let(:link_relative)                   { find_by_title(site.collections["file_path"].docs, "Relative File Path Link") }
  # let(:link_dup_name)                   { find_by_title(site.collections["file_path"].docs, "Duplicate Filename Link") }  
  # targets
  let(:blank_a)                         { find_by_title(site.collections["target"].docs, "Blank A") }
  let(:nested)                          { find_by_title(site.collections["target"].docs, "Nested Target") }
  
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

  context "ABSOLUTE FILE PATH UNTYPED [[wikilinks]]" do

    context "when target doc exists" do

      context "html output" do

        it "full" do
          expect(link_absolute.output).to eq("<p>This doc contains a wikilink to <a class=\"wiki-link\" href=\"/target/blank.a/\">blank a</a> using its absolute file path.</p>\n")
        end

        it "injects 'a' tag" do
          expect(link_absolute.output).to include("<a")
          expect(link_absolute.output).to include("</a>")
        end

        it "assigns 'wiki-link' class to 'a' tag" do
          expect(link_absolute.output).to include("class=\"wiki-link\"")
        end

        it "assigns 'a' tag's 'href' to document url" do
          expect(link_absolute.output).to include("href=\"/target/blank.a/\"")
        end

        it "generates a clean url when configs assign 'permalink' to 'pretty'" do
          expect(link_absolute.output).to_not include(".html")
        end

        it "downcases title in wikilink's rendered text" do
          expect(link_absolute.output).to include('>' + blank_a.data['title'].downcase + '<')
        end

      end

      context "metadata:" do
        
        it "'attributed' not added to either document" do
          expect(link_absolute.data['attributed']).to eq([])
          expect(blank_a.data['attributed']).to eq([])
        end

        it "'attributes' not added to either document" do
          expect(link_absolute.data['attributes']).to eq([])
          expect(blank_a.data['attributes']).to eq([])
        end

        context "'backlinks'" do

          it "not added to original document" do
            expect(link_absolute.data['backlinks']).to eq([])
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
            expect(blank_a.data['backlinks'][0]['url']).to eq("/file_path/link/")
          end

        end

        context "'forelinks'" do

          it "is added to document" do
            expect(link_absolute.data['forelinks']).to_not eq([])
          end

          it "contain array of hashes with keys 'type' and 'url'" do
            expect(link_absolute.data['forelinks']).to be_a(Array)
            expect(link_absolute.data['forelinks'][0].keys).to eq([ "type", "url" ])
          end

          it "not added to linked document" do
            expect(blank_a.data['forelinks']).to eq([])
          end

        end

      end

      # context "when multiple docs share target doc's filename" do

      #   context "html output" do

      #     it "full" do
      #       expect(link_dup_name.output).to eq("<p>This doc contains a wikilink to <span class=\"invalid-wiki-link\">[[/_nested/nested_dir/target.nested]]</span> using its absolute file path.</p>\n\n<p>This is to verify the doc’s full path is included, not just the parent directory.\nIt should be an invalid link: <span class=\"invalid-wiki-link\">[[/_nested/excluded]]</span></p>\n")
      #     end

      #   end

      # end

      # this test also attempts to target subdirectories whose 
      # parents don't include markdown files for processing.
      context "when target doc exists in nested directory" do

        context "html output" do

          it "full" do
            expect(link_absolute_nested.output).to eq("<p>This doc contains a wikilink to <a class=\"wiki-link\" href=\"/target/subdir/nested/\">nested target</a> using its absolute file path.</p>\n")
          end

        end

      end

    end

  end

  # context "RELATIVE FILE PATH UNTYPED [[wikilinks]]" do

  #   context "when target doc exists" do

  #     context "html output" do

  #       pending("TODO")

  #     end

  #   end

  # end

end
