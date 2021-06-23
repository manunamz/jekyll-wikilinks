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

  let(:label)                           { find_by_title(site.collections["docs"].docs, "Labelled") }
  let(:link_header_label)               { find_by_title(site.collections["docs"].docs, "Link Header Labelled") }
  let(:label_sq_br)                     { find_by_title(site.collections["docs"].docs, "Labelled With Square Brackets") }
  let(:label_missing_doc)               { find_by_title(site.collections["docs"].docs, "Labelled Missing Doc") }
  let(:labelled_link_header_missing)    { find_by_title(site.collections["docs"].docs, "Labelled Link Header Missing") }  

  # makes markdown tests work
  subject { described_class.new(site.config) }

  before(:each) do
    site.reset
    site.process
  end

  # todo: change to :each
  after(:all) do
    # cleanup generated assets
    FileUtils.rm_rf(Dir["#{fixtures_dir("/assets/graph-net-web.json")}"])
    # cleanup _site/ dir
    FileUtils.rm_rf(Dir["#{site_dir()}"])
  end

  context "when target [[wikilink]] using piped labels exists" do

    it "renders the label text, not the doc's  filename" do
      expect(label.output).to include("label")
      expect(label.output).to_not include("base-case.a")
    end

    it "full output" do
      expect(label.output).to eq("<p>This doc uses a <a class=\"wiki-link\" href=\"/doc/8f6277a1-b63a-4ac7-902d-d17e27cb950c/\">label</a>.</p>\n")
    end

    # labelled text preserves [square brackets]
    it "renders the label text with [square brackets], not the doc's  filename" do
      pending("flexible label text")
      expect(label_sq_br.output).to include("label with [square brackets]")
      expect(label_sq_br.output).to_not include("base-case.a")
    end

    it "full output" do
      pending("flexible label text")
      expect(label_sq_br.output).to eq("<p>This doc uses a <a class=\"wiki-link\" href=\"/doc/8f6277a1-b63a-4ac7-902d-d17e27cb950c/\">label with [square brackets]</a>.</p>\n")
    end

    # header fragment

    it "header url fragments contain doc's filename and header text" do
      expect(link_header_label.output).to include("labelled text")
    end

    it "header url fragment in url" do
      expect(link_header_label.output).to include("/docs/long-doc/#two")
    end

    it "processes header url fragments; full output" do
      expect(link_header_label.output).to eq("<p>This doc contains a link to a header with <a class=\"wiki-link\" href=\"/docs/long-doc/#two\">labelled text</a>.</p>\n")
    end
  
  end

  context "when target [[wikilink]] using piped labels does not exist" do

    it "injects a span element with descriptive title" do
      expect(label_missing_doc.output).to include("<span title=\"Content not found.\"")
      expect(label_missing_doc.output).to include("</span>")
    end

    it "assigns 'invalid-wiki-link' class to span element" do
      expect(label_missing_doc.output).to include("class=\"invalid-wiki-link\"")
    end

    it "leaves original angle brackets and text untouched" do
      expect(label_missing_doc.output).to include("[[no.doc|label]]")
    end

    it "full output" do
      expect(label_missing_doc.output).to eq("<p>This doc uses a <span title=\"Content not found.\" class=\"invalid-wiki-link\">[[no.doc|label]]</span>.</p>\n")
    end

    # header fragment

    it "assigns 'invalid-wiki-link' class to span element" do
      expect(labelled_link_header_missing.output).to include("class=\"invalid-wiki-link\"")
    end

    it "leaves original angle brackets and text untouched" do
      expect(labelled_link_header_missing.output).to include("[[long-doc#Zero|labelled text]]")
    end

    it "processes header url fragments; full output" do
      expect(labelled_link_header_missing.output).to eq("<p>This doc contains an invalid link fragment to <span title=\"Content not found.\" class=\"invalid-wiki-link\">[[long-doc#Zero|labelled text]]</span>.</p>\n")
    end
  end
end