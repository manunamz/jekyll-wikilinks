# frozen_string_literal: true
require "jekyll"
require "jekyll-wikilinks"
require "spec_helper"

RSpec.describe(JekyllWikiLinks::Generator) do
  let(:config_overrides) { {} }
  let(:config) do
    Jekyll.configuration(
      config_overrides.merge(
        "collections"          => { "notes" => { "output" => true } },
        "permalink"            => "pretty",
        "skip_config_files"    => false,
        "source"               => fixtures_dir,
        "destination"          => fixtures_dir("_site"),
        "url"                  => "garden.testsite.com",
        # "baseurl"              => "",
      )
    )
  end
  let(:site)                     { Jekyll::Site.new(config) }
  let(:one_note_md)              { File.read(fixtures_dir("_notes/one.fish.md")) }
  let(:one_note)                 { find_by_title(site.collections["notes"].docs, "One Fish") }
  let(:two_note)                 { find_by_title(site.collections["notes"].docs, "Two Fish") }
  let(:missing_link_note)        { find_by_title(site.collections["notes"].docs, "None Fish") }
  let(:missing_links_note)       { find_by_title(site.collections["notes"].docs, "None School") }
  let(:missing_right_alias_note) { find_by_title(site.collections["notes"].docs, "None Right Name Fish") }
  let(:missing_left_alias_note)  { find_by_title(site.collections["notes"].docs, "None Left Name Fish") }
  let(:right_alias_note)         { find_by_title(site.collections["notes"].docs, "Right Name Fish") }
  let(:left_alias_note)          { find_by_title(site.collections["notes"].docs, "Left Name Fish") }
  
  # check: https://github.com/benbalter/jekyll-relative-links/blob/ed1fe60243ef24769f442c0366647e2d1c8f50fe/spec/jekyll-relative-links/generator_spec.rb
  # how are 'detecting markdown' tests working without this?
  # subject { described_class.new(site.config) }

  before(:each) do
    site.reset
    site.process
  end

  context "run requirements" do

    it "processes markdown files" do
      expect(one_note.data['ext']).to eql(".md")
    end

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
      expect(one_note.output).to include("/wikilinks")
    end

    it "wiki-links are parsed and a element is generated" do
      expect(one_note.output).to eq("<p>This <a class=\"wiki-link\" href=\"/wikilinks/note/e0c824b6-0b8c-4595-8032-b6889edd815f/\">two fish</a> has a littlecar.</p>\n")
    end

  end

  context "when target [[wikilink]] note exists" do

    it "injects a element" do
      expect(one_note.output).to include("<a")
      expect(one_note.output).to include("</a>")

      expect(two_note.output).to include("<a")
      expect(two_note.output).to include("</a>")
    end

    it "assigns 'wiki-link' class to a element" do
      expect(one_note.output).to include("class=\"wiki-link\"")
      expect(two_note.output).to include("class=\"wiki-link\"")
    end

    it "assigns a element's href to site.baseurl + /note/ + note-id" do
      expect(one_note.output).to include("href=\"/note/e0c824b6-0b8c-4595-8032-b6889edd815f/\"")
      expect(two_note.output).to include("href=\"/note/8f6277a1-b63a-4ac7-902d-d17e27cb950c/\"")
    end

    # todo: add test for '.html' when 'permalink' is not set to 'pretty'
    it "generates a clean url when configs assign 'permalink' to 'pretty'" do
      expect(one_note.output).to_not include(".html")
      expect(two_note.output).to_not include(".html")
    end

    it "full output" do
      expect(one_note.output).to eq("<p>This <a class=\"wiki-link\" href=\"/note/e0c824b6-0b8c-4595-8032-b6889edd815f/\">two fish</a> has a littlecar.</p>\n")
      expect(two_note.output).to eq("<p>This <a class=\"wiki-link\" href=\"/note/8f6277a1-b63a-4ac7-902d-d17e27cb950c/\">one fish</a> has a little star.</p>\n")
    end

  end

  context "when target [[wikilink]] note does not exist" do
    
    it "injects a span element with descriptive title" do
      expect(missing_link_note.output).to include("<span title=\"There is no note that matches this link.\"")
      expect(missing_link_note.output).to include("</span>")
      expect(missing_links_note.output).to include("<span title=\"There is no note that matches this link.\"").twice
      expect(missing_links_note.output).to include("</span>").twice
    end

    it "assigns 'invalid-wiki-link' class to span element" do
      expect(missing_link_note.output).to include("class=\"invalid-wiki-link\"")
      expect(missing_links_note.output).to include("class=\"invalid-wiki-link\"").twice
    end

    it "leaves original angle brackets and text untouched" do
      expect(missing_link_note.output).to include("[[no.fish]]")
      expect(missing_links_note.output).to include("[[no.fish]]")
      expect(missing_links_note.output).to include("[[not.fish]]")
    end

    it "full output" do
      expect(missing_link_note.output).to eq("<p>This <span title=\"There is no note that matches this link.\" class=\"invalid-wiki-link\">[[no.fish]]</span> has no target.</p>\n")
      expect(missing_links_note.output).to eq("<p>This fish has no targets like <span title=\"There is no note that matches this link.\" class=\"invalid-wiki-link\">[[no.fish]]</span> and <span title=\"There is no note that matches this link.\" class=\"invalid-wiki-link\">[[not.fish]]</span>.</p>\n")
    end
  
  end

  context "when target [[wikilink]] using piped aliasing exists" do
    # [[fish|right alias]]
    # [[left alias|fish]]

    it "renders the alias text, not the note's filename" do
      expect(right_alias_note.output).to include("fish")
      expect(right_alias_note.output).to_not include("one.fish")
      expect(left_alias_note.output).to include("fish")
      expect(left_alias_note.output).to_not include("one.fish")
    end

    it "full output" do
      expect(right_alias_note.output).to eq("<p>This <a class=\"wiki-link\" href=\"/note/8f6277a1-b63a-4ac7-902d-d17e27cb950c/\">fish</a> uses a right alias.</p>\n")
      expect(left_alias_note.output).to eq("<p>This <a class=\"wiki-link\" href=\"/note/8f6277a1-b63a-4ac7-902d-d17e27cb950c/\">fish</a> uses a left alias.</p>\n")
    end
  
  end

  context "when target [[wikilink]] using piped aliasing does not exist" do
    # [[fish|right alias]]
    # [[left alias|fish]]

    it "injects a span element with descriptive title" do
      expect(missing_right_alias_note.output).to include("<span title=\"There is no note that matches this link.\"")
      expect(missing_right_alias_note.output).to include("</span>")
      expect(missing_left_alias_note.output).to include("<span title=\"There is no note that matches this link.\"")
      expect(missing_left_alias_note.output).to include("</span>")
    end

    it "assigns 'invalid-wiki-link' class to span element" do
      expect(missing_right_alias_note.output).to include("class=\"invalid-wiki-link\"")
      expect(missing_left_alias_note.output).to include("class=\"invalid-wiki-link\"")
    end

    it "leaves original angle brackets and text untouched" do
      expect(missing_right_alias_note.output).to include("[[no.fish|fish]]")
      expect(missing_left_alias_note.output).to include("[[fish|no.fish]]")
    end

    it "full output" do
      expect(missing_right_alias_note.output).to eq("<p>This <span title=\"There is no note that matches this link.\" class=\"invalid-wiki-link\">[[no.fish|fish]]</span> uses a right alias.</p>\n")
      expect(missing_left_alias_note.output).to eq("<p>This <span title=\"There is no note that matches this link.\" class=\"invalid-wiki-link\">[[fish|no.fish]]</span> uses a left alias.</p>\n")
    end

  end

end
