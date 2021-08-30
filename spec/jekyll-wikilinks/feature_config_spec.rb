# frozen_string_literal: true

require "jekyll-wikilinks"
require "spec_helper"
require "shared_context"

RSpec.describe(Jekyll::WikiLinks) do
  include_context "shared jekyll configs"

  let(:site)                            { Jekyll::Site.new(config) }

  # links
  let(:inline_untyped_link)             { find_by_title(site.collections["untyped"].docs, "Untyped Link") }
  # targets
  let(:blank_a)                         { find_by_title(site.collections["target"].docs, "Blank A") }
  let(:css_exclude)                     { find_by_title(site.collections["target"].docs, "Excluded CSS") }
  let(:one_page)                        { find_by_title(site.pages, "One Page") }

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

  context "CONFIG [[wikilinks]]" do

    context "when 'baseurl' is set in configs" do
      let(:config_overrides) { {
        "collections" => { "untyped" => { "output" => true }, "target" => { "output" => true } },
        "baseurl" => "/wikilinks",
      } }

      it "baseurl included in href" do
        expect(inline_untyped_link.output).to include("/wikilinks")
      end

      it "wiki-links are parsed and 'a' tag is generated" do
        expect(inline_untyped_link.output).to eq("<p>This doc contains a wikilink to <a class=\"wiki-link\" href=\"/wikilinks/target/blank.a/\">blank a</a>.</p>\n")
      end

    end

    context "when jekyll-wikilinks is disabled in configs" do
      let(:config_overrides) { {
        "collections" => { "untyped" => { "output" => true }, "target" => { "output" => true } },
        "wikilinks" => { "enabled" => false },
      } }

      it "does not process [[wikilinks]]" do
        expect(inline_untyped_link.output).to include("[[blank.a]]")
      end

    end

    context "when certain jekyll types are excluded in configs" do
      let(:config_overrides) { {
        "collections" => { "untyped" => { "output" => true }, "target" => { "output" => true } },
        "wikilinks" => { "exclude" => ["untyped", "pages", "posts"] },
      } }

      it "does not process [[wikilinks]] for those types" do
        expect(inline_untyped_link.output).to include("[[blank.a]]")
      end

    end

    context "when css classes are excluded" do
      let(:config_overrides) { {
        "collections" => { "untyped" => { "output" => true }, "target" => { "output" => true } },
        "wikilinks" => { "css" => { "exclude" => [ "exclude-link" ] } },
      } }

      it "does not classify 'a' tags as web links with excluded css classes" do
        expect(css_exclude.output).to_not include("web-link")
      end

      it "full output" do
        expect(css_exclude.output).to eq("<p>An <a class=\"exclude-link\" href=\"www.example.com\">excluded css class</a>.</p>\n")
      end

    end

  end

end
