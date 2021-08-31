# frozen_string_literal: true

require "jekyll-wikilinks"
require "spec_helper"
require "shared_context"

RSpec.describe(Jekyll::WikiLinks::Generator) do
  include_context "shared jekyll configs"

  let(:config_overrides)                { { "collections" => { "labelled" => { "output" => true }, "target" => { "output" => true } } } }
  let(:site)                            { Jekyll::Site.new(config) }

  # links
  let(:link)                          { find_by_title(site.collections["labelled"].docs, "Labelled Link") }
  let(:link_missing_doc)              { find_by_title(site.collections["labelled"].docs, "Labelled Link Missing Doc") }
  let(:link_w_sq_br)                  { find_by_title(site.collections["labelled"].docs, "Labelled With Square Brackets") }
  let(:link_lvl_header)               { find_by_title(site.collections["labelled"].docs, "Labelled Link Header") }
  let(:link_lvl_header_missing_header){ find_by_title(site.collections["labelled"].docs, "Labelled Link Header Missing") }
  # targets
  let(:blank_a)                       { find_by_title(site.collections["target"].docs, "Blank A") }
  let(:blank_b)                       { find_by_title(site.collections["target"].docs, "Blank B") }
  let(:lvl_block)                     { find_by_title(site.collections["target"].docs, "Level Block") }
  let(:lvl_header)                    { find_by_title(site.collections["target"].docs, "Level Header") }

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

  context "LABELLED UNTYPED [[wikilinks]]" do

    context "when target doc exists" do

      context "html output" do

        it "full" do
          expect(link.output).to eq("<p>This doc uses a <a class=\"wiki-link\" href=\"/target/blank.a/\">label</a>.</p>\n")
        end

        it "renders the label text, not the doc's  filename" do
          expect(link.output).to include(">" + "label" + "<")
          expect(link.output).to_not include(">" + "blank.a" + "<")
        end

      end

      context "when label includes [square brackets]; html output" do

        context "current function:" do

          it "full" do
            expect(link_w_sq_br.output).to eq("<p>This doc uses a <a class=\"wiki-link\" href=\"/target/blank.b/\">label with [square brackets</a>].</p>\n")
          end

          it "renders the label text with [square brackets], not the doc's  filename" do
            expect(link_w_sq_br.output).to include("label with [square brackets")
            rendered_filename = ">blank.b"
            expect(link_w_sq_br.output).to_not include(rendered_filename)
          end

        end

        context "desired function:" do

          it "full" do
            pending("REGEX_NOT_GREEDY still not quite right...")
            expect(link_w_sq_br.output).to eq("<p>This doc uses a <a class=\"wiki-link\" href=\"/target/blank.b/\">label with [square brackets]</a>.</p>\n")
          end

          it "renders the label text with [square brackets], not the doc's  filename" do
            pending("REGEX_NOT_GREEDY still not quite right...")
            expect(link_w_sq_br.output).to include("label with [square brackets]")
            rendered_filename = ">blank.b"
            expect(link_w_sq_br.output).to_not include(rendered_filename)
          end

        end

      end

      context "level:" do

        context "#header" do

          context "html output" do

            it "full" do
              expect(link_lvl_header.output).to eq("<p>This doc contains a link to a header <a class=\"wiki-link\" href=\"/target/lvl.header/#a-header\">label</a>.</p>\n")
            end

            it "header url fragments contain doc's filename and header text" do
              expect(link_lvl_header.output).to include("label")
            end

            it "header url fragment in url" do
              expect(link_lvl_header.output).to include("/target/lvl.header/#a-header")
            end

          end

        end

        context "^block" do

        end

      end

    end

    context "when target doc does not exist" do

      context "html output" do

        it "full" do
          expect(link_missing_doc.output).to eq("<p>This doc contains a wikilink to <span class=\"invalid-wiki-link\">[[missing.doc|label]]</span>.</p>\n")
        end

        it "injects a span element with descriptive title" do
          expect(link_missing_doc.output).to include("<span ")
          expect(link_missing_doc.output).to include("</span>")
        end

        it "assigns 'invalid-wiki-link' class to span element" do
          expect(link_missing_doc.output).to include("class=\"invalid-wiki-link\"")
        end

        it "leaves original angle brackets and text untouched" do
          expect(link_missing_doc.output).to include("[[missing.doc|label]]")
        end

      end

      context "level:" do

        context "#header" do

          context "html output" do

            it "full" do
              expect(link_lvl_header_missing_header.output).to eq("<p>This doc contains an invalid link fragment to <span class=\"invalid-wiki-link\">[[blank.c#header|label]]</span>.</p>\n")
            end

            it "assigns 'invalid-wiki-link' class to span element" do
              expect(link_lvl_header_missing_header.output).to include("class=\"invalid-wiki-link\"")
            end

            it "leaves original angle brackets and text untouched" do
              expect(link_lvl_header_missing_header.output).to include("[[blank.c#header|label]]")
            end

          end

        end

        context "^block" do

        end

      end

    end

  end

  context "LABELLED UNTYPED [[wikilinks]]" do

    context "when target doc exists" do

      context "html output" do

        pending("TODO")

      end

    end

  end

end
