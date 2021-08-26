# frozen_string_literal: true

require "jekyll-wikilinks"
require "spec_helper"
require "shared_context"

RSpec.describe(Jekyll::WikiLinks::Generator) do
  include_context "shared jekyll configs"
  let(:config_overrides) { {} }
  let(:site)                            { Jekyll::Site.new(config) }

  let(:base_case_a)                     { find_by_title(site.collections["docs"].docs, "Base Case A") }
  let(:base_case_b)                     { find_by_title(site.collections["docs"].docs, "Base Case B") }
  let(:one_page)                        { find_by_title(site.pages, "One Page") }
  let(:web_link_exclude)                { find_by_title(site.collections["docs"].docs, "Excluded Web Link") }

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

  it "saves the config" do
    expect(subject.config).to eql(site.config)
  end

  context "processes markdown" do

    context "detecting markdown" do
      before { subject.instance_variable_set "@site", site }

      it "knows when an extension is markdown" do
        expect(subject.send(:markdown_extension?, ".md")).to eql(true)
      end

      it "knows when an extension isn't markdown" do
        expect(subject.send(:markdown_extension?, ".html")).to eql(false)
      end

      it "knows the markdown converter" do
        expect(subject.send(:markdown_converter)).to be_a(Jekyll::Converters::Markdown)
      end
    end

  end

  context "when 'baseurl' is set in configs" do
    let(:config_overrides) { { "baseurl" => "/wikilinks" } }

    it "baseurl included in href" do
      expect(base_case_a.output).to include("/wikilinks")
    end

    it "wiki-links are parsed and a element is generated" do
      expect(base_case_a.output).to eq("<p>This <a class=\"wiki-link\" href=\"/wikilinks/doc/e0c824b6-0b8c-4595-8032-b6889edd815f/\">base case b</a> has a littlecar.</p>\n")
    end

  end

  context "when jekyll-wikilinks is disabled in configs" do
    let(:config_overrides) { { "wikilinks" => { "enabled" => false } } }

    it "does not process [[wikilinks]]" do
      expect(base_case_a.content).to include("[[base-case.b]]")
    end

  end

  context "when certain jekyll types are excluded in configs" do
    let(:config_overrides) { { "wikilinks" => { "exclude" => ["docs", "pages", "posts"] } } }

    it "does not process [[wikilinks]] for those types" do
      expect(base_case_a.content).to include("[[base-case.b]]")
      expect(one_page.content).to include("[[base-case.a]]")
    end

  end

  context "when css classes are excluded" do
    let(:config_overrides) { { "wikilinks" => { "css" => { "exclude" => [ "exclude-link" ] } } } }

    it "does not classify 'a' tags as web links with excluded css classes" do
      expect(web_link_exclude.content).to_not include("web-link")
    end

    it "full output" do
      expect(web_link_exclude.content).to eq("<p>An <a class=\"exclude-link\" href=\"www.example.com\">excluded link</a>.</p>\n")
    end

  end

end
