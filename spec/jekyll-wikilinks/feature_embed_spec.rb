# frozen_string_literal: true

require "jekyll-wikilinks"
require "spec_helper"
require "shared_context"

RSpec.describe(Jekyll::WikiLinks::Generator) do
  include_context "shared jekyll configs"

  let(:config_overrides)                { { "collections" => { "embed" => { "output" => true }, "target" => { "output" => true } } } }
  let(:site)                            { Jekyll::Site.new(config) }

  # links
  let(:link)                            { find_by_title(site.collections["embed"].docs, "Embed Link") }
  let(:link_nested_link)                { find_by_title(site.collections["embed"].docs, "Embed Link Nested") }
  let(:link_img)                        { find_by_title(site.collections["embed"].docs, "Embed Link Image") }
  let(:link_img_svg)                    { find_by_title(site.collections["embed"].docs, "Embed Link Image SVG") }
  # targets
  let(:some_txt_a)                      { find_by_title(site.collections["target"].docs, "Some Text A") }
  let(:some_txt_b)                      { find_by_title(site.collections["target"].docs, "Some Text B") }
  let(:nested_link)                     { find_by_title(site.collections["embed"].docs, "Nested Content") }


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

  context "EMBEDDED UNTYPED [[wikilinks]]" do

    context "when target doc exists" do

      context "html output" do

        it "full" do
          expect(link.output).to eq("<p>The following link should be embedded:</p>

<div class=\"embed-wrapper\">
<div class=\"embed-title\">Some Text A</div>
<div class=\"embed-content\"><p>There is minimal text in this document.</p></div>
<a class=\"embed-wiki-link\" href=\"/target/some-txt.a/\"></a>
</div>\n")
        end

        it "adds embed title div with 'embed-wrapper' class" do
          expect(link.output).to include("<div class=\"embed-wrapper\">")
        end

        it "adds embed title div with 'embed-title' class" do
          expect(link.output).to include("<div class=\"embed-title\">")
        end

        it "adds embed title div with 'embed-content' class" do
          expect(link.output).to include("<div class=\"embed-content\">")
        end

        it "adds embed a element link with 'embed-wiki-link' class" do
          expect(link.output).to include("<a class=\"embed-wiki-link\"")
        end

      end

      context "with nested links" do

        it "full output" do
          pending("this works in actuality, but the tests fail...and they should fail...i don't understand why this works.")
          expect(link_nested_link.output).to eq("")
        end

        it "converts/'markdownifies' nested content" do
          pending("this works in actuality, but the tests fail...and they should fail...i don't understand why this works.")
          expect(link_nested_link.output).to include("<p>This document has a link and when it’s embedded, that link should be rendered as a wikilink.</p>\n<a class=\"wiki-link-embed-link\" href=\"/target/some-txt.b/\"></a>")
        end

      end

      context "levels" do

        # header fragment
        it "processes header url fragments; full output" do
          pending("embedded header fragment")
          expect(1).to eq(2)
        end

        # block fragment
        it "processes header url fragments; full output" do
          pending("embedded block fragment")
          expect(1).to eq(2)
        end

      end

      context "when ![[embed]] is an image"

        it "embeds png in 'img' tag; full output" do
          expect(link_img.output).to eq("<p>The following link should be embedded:</p>\n\n<p><span class=\"embed-image-wrapper\"><img class=\"embed-image\" src=\"/assets/image.png\"></span></p>\n")
        end

        it "embeds svg file contents directly (instead of nesting in an <img> tag)" do
          expect(link_img_svg.output).to include("<svg")
          expect(link_img_svg.output).to include("</svg>")
        end

      end

    end

    context "EMBEDDED TYPED [[wikilinks]]" do

      pending("TODO")

    end

end
