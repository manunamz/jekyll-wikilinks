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
  
  let(:embed)                           { find_by_title(site.collections["docs"].docs, "Embed") }
  let(:embed_long)                      { find_by_title(site.collections["docs"].docs, "Embed Long") }
  let(:embed_img)                       { find_by_title(site.collections["docs"].docs, "Embed Image") }
  
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

  context "when target embedded ![[wikilink]] exists" do

    it "adds embed div wrapper with 'wiki-link-embed' class" do
      expect(embed.output).to include("<div class=\"wiki-link-embed\">")
    end

    it "adds embed title div with 'wiki-link-embed-title' class" do
      expect(embed.output).to include("<div class=\"wiki-link-embed-title\">")
    end

    it "adds embed link div with 'wiki-link-embed' class" do
      expect(embed.output).to include("<div class=\"wiki-link-embed-link\">")
    end

    it "full output; short" do
      expect(embed.output).to eq("<p>The following link should be embedded:</p>\n\n<div class=\"wiki-link-embed\"><div class=\"wiki-link-embed-title\">Base Case A</div><div class=\"wiki-link-embed-content\"><p>This <a class=\"wiki-link\" href=\"/doc/e0c824b6-0b8c-4595-8032-b6889edd815f/\">base case b</a> has a littlecar.</p></div><div class=\"wiki-link-embed-link\"><a href=\"/doc/8f6277a1-b63a-4ac7-902d-d17e27cb950c/\"></a></div></div>\n")
    end

    it "converts/'markdownifies' nested content'" do
      expect(embed_long.output).to include("<div class=\"wiki-link-embed-content\"><h1 id=\"one\">One</h1><ul>  <li>a</li>  <li>b</li>  <li>c    <h1 id=\"two\">Two</h1>  </li>  <li>d</li>  <li>e</li>  <li>f    <h1 id=\"three\">Three</h1>  </li>  <li>g</li>  <li>h</li>  <li>i    <h1 id=\"four\">Four</h1>  </li>  <li>This is some text to test out blocks. ^block_id</li></ul><p>Some more text to verify that block_id captures are not over-capturing.</p></div>")
    end

    it "full output; long" do
      expect(embed_long.output).to eq("<p>The following link should be embedded:</p>\n\n<div class=\"wiki-link-embed\"><div class=\"wiki-link-embed-title\">Long Doc</div><div class=\"wiki-link-embed-content\"><h1 id=\"one\">One</h1><ul>  <li>a</li>  <li>b</li>  <li>c    <h1 id=\"two\">Two</h1>  </li>  <li>d</li>  <li>e</li>  <li>f    <h1 id=\"three\">Three</h1>  </li>  <li>g</li>  <li>h</li>  <li>i    <h1 id=\"four\">Four</h1>  </li>  <li>This is some text to test out blocks. ^block_id</li></ul><p>Some more text to verify that block_id captures are not over-capturing.</p></div><div class=\"wiki-link-embed-link\"><a href=\"/docs/long-doc/\"></a></div></div>\n")
    end
    
    # header fragment

    it "processes header url fragments; full output" do
      pending("proper parse tree; embedded header fragment")
      expect(1).to eq(2)
      # expect(embed_header_long.output).to eq("")
    end
  
    # block fragment

    it "processes header url fragments; full output" do
      pending("proper parse tree; embedded block fragment")
      expect(1).to eq(2)
      # expect(embed_block_long.output).to eq("")
    end

    # images

    it "processes images" do
      expect(embed_img.output).to eq("<p>The following link should be embedded:</p>\n\n<p><span class=\"wiki-link-embed-image\"><img class=\"wiki-link-img\" src=\"/assets/image.png\" /></span></p>\n")
    end
  end
end