# frozen_string_literal: true
require "jekyll"
require "jekyll-wikilinks"
require "spec_helper"

RSpec.describe(JekyllWikilinks) do
  let(:config_overrides) { {} }
  let(:config) do
    Jekyll.configuration(
      config_overrides.merge(
        "skip_config_files" => false,
        "collections"       => { "notes" => { "output" => true } },
        "source"            => fixtures_dir,
        "destination"       => fixtures_dir("_site"),
        "baseurl"           => "garden.testsite.com"
      )
    )
  end
  let(:site)                { Jekyll::Site.new(config) }
  let(:one_note_md)         { File.read(fixtures_dir("_notes/one.fish.md")) }
  let(:one_note)            { find_by_title(site.collections["notes"].docs, "One Fish") }
  let(:two_note)            { find_by_title(site.collections["notes"].docs, "Two Fish") }
  let(:missing_link_note)   { find_by_title(site.collections["notes"].docs, "None Fish") }
  let(:right_alias_note)    { find_by_title(site.collections["notes"].docs, "Right Name Fish") }
  let(:left_alias_note)     { find_by_title(site.collections["notes"].docs, "Left Name Fish") }
  
  before(:each) do
    site.process
  end

  context "note file requirements" do

    it "processes markdown files" do
      expect(one_note.data['ext']).to eql(".md")
    end

    it "expects these data in note's frontmatter" do
      # file
      expect(one_note_md).to include("id:")
      expect(one_note_md).to include("title:")
      expect(one_note_md).to include("permalink:")
      # note data
      expect(one_note.data).to include("id")
      expect(one_note.data).to include("title")
      expect(one_note.data).to include("permalink")      
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
      expect(one_note.output).to include("href=\"garden.testsite.com/note/e0c824b6-0b8c-4595-8032-b6889edd815f/\"")
      expect(two_note.output).to include("href=\"garden.testsite.com/note/8f6277a1-b63a-4ac7-902d-d17e27cb950c/\"")
    end

    it "full output" do
      expect(one_note.output).to eq("<p>This <a class=\"wiki-link\" href=\"garden.testsite.com/note/e0c824b6-0b8c-4595-8032-b6889edd815f/\">fish</a> has a littlecar.</p>\n")
      expect(two_note.output).to eq("<p>This <a class=\"wiki-link\" href=\"garden.testsite.com/note/8f6277a1-b63a-4ac7-902d-d17e27cb950c/\">fish</a> has a little star.</p>\n")
    end

  end

  context "when target [[wikilink]] note does not exist" do
    
    it "injects a span element with descriptive title" do
      expect(missing_link_note.output).to include("<span title=\"There is no note that matches this link.\"")
      expect(missing_link_note.output).to include("</span>")
    end

    it "assigns 'invalid-wiki-link' class to span element" do
      expect(missing_link_note.output).to include("class=\"invalid-wiki-link\"")
    end

    it "leaves original angle brackets and text untouched" do
      expect(missing_link_note.output).to include("[[wat.fish]]")
    end

    it "full output" do
      expect(missing_link_note.output).to eq("<p>This <span title=\"There is no note that matches this link.\" class=\"invalid-wiki-link\">[[wat.fish]]</span> has no target.</p>\n")
    end
  
  end

  context "when target [[wikilink]] uses piped aliasing" do
    # [[fish|right alias]]
    # [[left alias|fish]]

    it "renders the alias text, not the note's filename" do
      expect(right_alias_note.output).to include("fish")
      expect(right_alias_note.output).to_not include("one.fish")
      expect(left_alias_note.output).to include("fish")
      expect(left_alias_note.output).to_not include("one.fish")
    end

    it "full output" do
      expect(right_alias_note.output).to eq("<p>This <a class=\"wiki-link\" href=\"garden.testsite.com/note/8f6277a1-b63a-4ac7-902d-d17e27cb950c/\">fish</a> uses a right alias.</p>\n")
      expect(left_alias_note.output).to eq("<p>This <a class=\"wiki-link\" href=\"garden.testsite.com/note/8f6277a1-b63a-4ac7-902d-d17e27cb950c/\">fish</a> uses a left alias.</p>\n")
    end
  
  end

end
