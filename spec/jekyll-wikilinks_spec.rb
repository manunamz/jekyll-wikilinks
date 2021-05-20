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
        "destination"          => site_dir,
        "url"                  => "garden.testsite.com",
        # "baseurl"              => "",
      )
    )
  end
  let(:site)                     { Jekyll::Site.new(config) }
  let(:graph_generated_file)     { find_generated_file("/assets/graph-net-web.json") }
  let(:graph_static_file)        { find_static_file("/assets/graph-net-web.json") }
  let(:graph_data)               { static_graph_file_content() }
  let(:graph_node)               { a_graph_node() }
  let(:graph_link)               { a_graph_link() }
  let(:one_page)                 { find_by_title(site.pages, "One Page") }
  let(:one_post)                 { find_by_title(site.collections["posts"].docs, "One Post") }
  let(:one_note)                 { find_by_title(site.collections["notes"].docs, "One Fish") }
  let(:two_note)                 { find_by_title(site.collections["notes"].docs, "Two Fish") }
  let(:link_to_page_note)        { find_by_title(site.collections["notes"].docs, "Link Page") }
  let(:link_to_post_note)        { find_by_title(site.collections["notes"].docs, "Link Post") }
  let(:missing_link_note)        { find_by_title(site.collections["notes"].docs, "None Fish") }
  let(:missing_links_note)       { find_by_title(site.collections["notes"].docs, "None School") }
  let(:missing_right_alias_note) { find_by_title(site.collections["notes"].docs, "None Right Name Fish") }
  let(:missing_left_alias_note)  { find_by_title(site.collections["notes"].docs, "None Left Name Fish") }
  let(:note_link_whitespace)     { find_by_title(site.collections["notes"].docs, "Link Name With Whitespace") }
  let(:note_name_whitespace)     { find_by_title(site.collections["notes"].docs, "Note Name With Whitespace") }
  let(:right_alias_note)         { find_by_title(site.collections["notes"].docs, "Right Name Fish") }
  let(:left_alias_note)          { find_by_title(site.collections["notes"].docs, "Left Name Fish") }
  
  # makes markdown tests work
  subject { described_class.new(site.config) }

  before(:each) do
    site.reset
    site.process
  end

  after(:all) do
    # cleanup generated assets
    FileUtils.rm_rf(Dir["#{fixtures_dir("/assets/graph-net-web.json")}"])
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

  # happy-path

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

    it "adds 'backlinks' metadata" do
      expect(one_note.data).to include("backlinks")
      expect(two_note.data).to include("backlinks")
    end

    it "'backlinks' metadata includes all jekyll types -- pages, docs (posts and collections)" do
      expect(one_note.data["backlinks"]).to include(Jekyll::Page)
      expect(one_note.data["backlinks"]).to include(Jekyll::Document)
      # 'two_note' does not include any pages in its backlinks
      # expect(two_note.data["backlinks"]).to include(Jekyll::Page)
      expect(two_note.data["backlinks"]).to include(Jekyll::Document)
    end

    it "full output" do
      expect(one_note.output).to eq("<p>This <a class=\"wiki-link\" href=\"/note/e0c824b6-0b8c-4595-8032-b6889edd815f/\">two fish</a> has a littlecar.</p>\n")
      expect(two_note.output).to eq("<p>This <a class=\"wiki-link\" href=\"/note/8f6277a1-b63a-4ac7-902d-d17e27cb950c/\">one fish</a> has a little star.</p>\n")
    end

    # graph

    it "generates graph data" do
      # expect(graph_generated_file.class).to be(File)
      # expect(graph_generated_file.ext).to be(".json")
      expect(graph_static_file).to be_a(Jekyll::StaticFile)
      expect(graph_static_file.relative_path).not_to be(nil)
      expect(graph_data.class).to be(Hash)
    end

    it "generated graph data contains nodes of format: { nodes: [ {id: '', url: '', label: ''}, ... ] }" do
      expect(graph_node.keys).to include("id")
      expect(graph_node.keys).to include("url")
      expect(graph_node.keys).to include("label")
    end

    it "nodes' 'id's equal their url (since urls should be unique)" do
      expect(graph_node["id"]).to eq(graph_node["url"])
    end

    it "nodes' 'label's equal their doc title" do
      expect(graph_node["label"]).to eq(one_note.data["title"])
    end

    it "nodes' 'url's equal their doc urls" do
      expect(graph_node["url"]).to eq(one_note.url)
    end

    it "generated graph data contains links of format: { links: [ { source: '', target: ''}, ... ] }" do
      expect(graph_link.keys).to include("source")
      expect(graph_link.keys).to include("target")
    end

    it "links' 'source' and 'target' attributes equal some nodes' id" do
      expect(graph_link["source"]).to eq(graph_node["id"])
      expect(graph_link["target"]).to eq("/note/e0c824b6-0b8c-4595-8032-b6889edd815f/")
    end

  end

  context "when jekyll-wikilinks is disabled in configs" do
    let(:config_overrides) { { "wikilinks" => { "enabled" => false } } }

    it "does not process [[wikilinks]]" do
      expect(one_note.content).to include("[[two.fish]]")
    end

  end

  context "when graph is disabled in configs" do
    let(:config_overrides) { { "d3_graph_data" => { "enabled" => false } } }
    before(:each) do
      # cleanup generated assets
      FileUtils.rm_rf(Dir["#{fixtures_dir("/assets/graph-net-web.json")}"])
      # cleanup site_dir dir
      FileUtils.rm_rf(Dir["#{site_dir()}"])
    end
    
    it "does not generate graph data" do
      expect { File.read("#{fixtures_dir("/assets/graph-net-web.json")}") }.to raise_error(Errno::ENOENT)
      expect { File.read("#{site_dir("/assets/graph-net-web.json")}") }.to raise_error(Errno::ENOENT)
    end

  end

  # /graph

  context "when 'baseurl' is set in configs" do
    let(:config_overrides) { { "baseurl" => "/wikilinks" } }

    it "baseurl included in href" do
      expect(one_note.output).to include("/wikilinks")
    end

    it "wiki-links are parsed and a element is generated" do
      expect(one_note.output).to eq("<p>This <a class=\"wiki-link\" href=\"/wikilinks/note/e0c824b6-0b8c-4595-8032-b6889edd815f/\">two fish</a> has a littlecar.</p>\n")
    end

  end

  context "when target [[wikilink]] note exists and contains whitespace" do
    
    it "[[wikilinks]] work as expected; full output" do
      expect(note_link_whitespace.output).to eq("<p>Link to <a class=\"wiki-link\" href=\"/note/fb6bf728-948f-489e-9c9f-bb2b92677192/\">note name with whitespace</a>.</p>\n")
    end

  end

  context "when [[wikilink]]s references cross jekyll types (collection item, post, or page)" do

    it "work as expected when post targets collection item; full output" do
      expect(one_post.output).to eq("<p>Posts support links, like to <a class=\"wiki-link\" href=\"/note/8f6277a1-b63a-4ac7-902d-d17e27cb950c/\">one fish</a>.</p>\n")
    end
    
    it "work as expected when collection item targets a post; full output" do
      expect(link_to_post_note.output).to eq("<p>This note links to <a class=\"wiki-link\" href=\"/2020/12/08/one-post/\">one post</a>.</p>\n")
    end

    it "work as expected when page targets collection item; full output" do
      expect(one_page.output).to eq("<p>This page links to a <a class=\"wiki-link\" href=\"/note/8f6277a1-b63a-4ac7-902d-d17e27cb950c/\">one fish</a>.</p>\n")
    end
    
    it "work as expected when collection item targets a page; full output" do
      expect(link_to_page_note.output).to eq("<p>This note links to <a class=\"wiki-link\" href=\"/one-page/\">one page</a>.</p>\n")
    end

    # todo: collection-type-1 <-> collection-type-2
    # todo: page <-> post

  end

  # /happy-path

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
