# frozen_string_literal: true

require "jekyll-wikilinks"
require "spec_helper"
require "shared_context"

RSpec.describe(Jekyll::WikiLinks::Generator) do
  include_context "shared jekyll configs"

  let(:config_overrides)              { { "collections" => { "untyped" => { "output" => true }, "target" => { "output" => true } } } }
  let(:site)                          { Jekyll::Site.new(config) }

  # targets
  let(:w_blockquote)                  { find_by_title(site.collections["target"].docs, "Blockquote") }
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

  context "WEB LINKS (non-wiki-links)" do

    it "full output" do
      expect(w_web_link.content).to eq("<p>A <a href=\"www.example.com\" class=\"web-link\">web link</a>.</p>\n")
    end

    it "have a 'web-link' css class added to their 'a' element" do
      expect(w_web_link.content).to include("web-link")
    end

    it "leaves blockquotes alone" do
      expect(w_blockquote.content).to eq("<blockquote>\n  <p>A blockquote.</p>\n</blockquote>\n")
    end

  end

end
