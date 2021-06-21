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
  let(:site)                            { Jekyll::Site.new(config) }
  
  # file link
  let(:base_case_a)                     { find_by_title(site.collections["notes"].docs, "Base Case A") }
  let(:base_case_b)                     { find_by_title(site.collections["notes"].docs, "Base Case B") }
  let(:one_page)                        { find_by_title(site.pages, "One Page") }
  let(:one_post)                        { find_by_title(site.collections["posts"].docs, "One Post") }
  let(:link_to_page_note)               { find_by_title(site.collections["notes"].docs, "Link Page") }
  let(:link_to_post_note)               { find_by_title(site.collections["notes"].docs, "Link Post") }
  let(:missing_doc)                     { find_by_title(site.collections["notes"].docs, "Missing Doc") }
  let(:missing_doc_many)                { find_by_title(site.collections["notes"].docs, "Missing Doc Many") }
  let(:link_whitespace_in_filename)     { find_by_title(site.collections["notes"].docs, "Link Whitespace In Filename") }
  let(:whitespace_in_filename)          { find_by_title(site.collections["notes"].docs, "Whitespace In Filename") }
  # typed links
  let(:typed_inline)                    { find_by_title(site.collections["notes"].docs, "Typed Link Inline") }
  let(:typed_block)                     { find_by_title(site.collections["notes"].docs, "Typed Link Block") }
  # header link/url fragments
  let(:link_header)                     { find_by_title(site.collections["notes"].docs, "Link Header") }
  let(:link_header_missing_doc)         { find_by_title(site.collections["notes"].docs, "Link Header Missing") }
  let(:link_header_label)               { find_by_title(site.collections["notes"].docs, "Link Header Labelled") }
  # block link
  let(:link_block)                      { find_by_title(site.collections["notes"].docs, "Link Block") }
  # labels
  let(:label)                           { find_by_title(site.collections["notes"].docs, "Labelled") }
  let(:label_sq_br)                     { find_by_title(site.collections["notes"].docs, "Labelled With Square Brackets") }
  let(:label_missing_doc)               { find_by_title(site.collections["notes"].docs, "Labelled Missing Doc") }
  let(:labelled_link_header_missing)    { find_by_title(site.collections["notes"].docs, "Labelled Link Header Missing") }  
  # embed
  let(:embed)                           { find_by_title(site.collections["notes"].docs, "Embed") }
  let(:embed_long)                      { find_by_title(site.collections["notes"].docs, "Embed Long") }
  let(:embed_img)                       { find_by_title(site.collections["notes"].docs, "Embed Image") }
  # graph
  let(:graph_generated_file)            { find_generated_file("/assets/graph-net-web.json") }
  let(:graph_static_file)               { find_static_file("/assets/graph-net-web.json") }
  let(:graph_data)                      { static_graph_file_content() }
  let(:graph_node)                      { get_graph_node() }
  let(:graph_link)                      { get_graph_link_match_source() }
  let(:missing_link_graph_node)         { get_missing_link_graph_node() }
  let(:missing_target_graph_link)       { get_missing_target_graph_link() }
  
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
      expect(base_case_a.output).to include("<a")
      expect(base_case_a.output).to include("</a>")

      expect(base_case_b.output).to include("<a")
      expect(base_case_b.output).to include("</a>")
    end

    it "assigns 'wiki-link' class to a element" do
      expect(base_case_a.output).to include("class=\"wiki-link\"")
      expect(base_case_b.output).to include("class=\"wiki-link\"")
    end

    it "assigns a element's href to site.baseurl + /note/ + note-id" do
      expect(base_case_a.output).to include("href=\"/note/e0c824b6-0b8c-4595-8032-b6889edd815f/\"")
      expect(base_case_b.output).to include("href=\"/note/8f6277a1-b63a-4ac7-902d-d17e27cb950c/\"")
    end

    # todo: add test for '.html' when 'permalink' is not set to 'pretty'
    it "generates a clean url when configs assign 'permalink' to 'pretty'" do
      expect(base_case_a.output).to_not include(".html")
      expect(base_case_b.output).to_not include(".html")
    end

    it "adds 'backlinks' metadata" do
      expect(base_case_a.data).to include("backlinks")
      expect(base_case_b.data).to include("backlinks")
    end

    it "adds 'link_types' metadata" do
      expect(base_case_a.data).to include("link_types")
      expect(base_case_b.data).to include("link_types")
    end

    it "'backlinks' metadata includes all jekyll types -- pages, docs (posts and collections)" do
      expect(base_case_a.data["backlinks"]).to include(Jekyll::Page)
      expect(base_case_a.data["backlinks"]).to include(Jekyll::Document)
      # 'base_case_b' does not include any pages in its backlinks
      # expect(base_case_b.data["backlinks"]).to include(Jekyll::Page)
      expect(base_case_b.data["backlinks"]).to include(Jekyll::Document)
    end

    it "full output" do
      expect(base_case_a.output).to eq("<p>This <a class=\"wiki-link\" href=\"/note/e0c824b6-0b8c-4595-8032-b6889edd815f/\">base case b</a> has a littlecar.</p>\n")
      expect(base_case_b.output).to eq("<p>This <a class=\"wiki-link\" href=\"/note/8f6277a1-b63a-4ac7-902d-d17e27cb950c/\">base case a</a> has a little star.</p>\n")
    end

    # header fragment

    it "header url fragments contain note name and header text" do
      expect(link_header.output).to include("long note &gt; Two")
    end

    it "header url fragment in url" do
      expect(link_header.output).to include("/notes/long-note/#two")
    end

    it "processes header url fragments; full output" do
      expect(link_header.output).to eq("<p>This note contains a link to a header <a class=\"wiki-link\" href=\"/notes/long-note/#two\">long note &gt; Two</a>.</p>\n")
    end

    # block fragment

    it "block url fragments contain note name and block id" do
      expect(link_block.output).to include("long note &gt; ^block_id")
    end

    it "block url fragment in url" do
      expect(link_block.output).to include("/notes/long-note/#block_id")
    end

    it "processes block url fragments; full output" do
      expect(link_block.output).to eq("<p>This note contains a link to a block <a class=\"wiki-link\" href=\"/notes/long-note/#block_id\">long note &gt; ^block_id</a>.</p>\n")
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
      expect(graph_node["label"]).to eq(base_case_a.data["title"])
    end

    it "nodes' 'url's equal their doc urls" do
      expect(graph_node["url"]).to eq(base_case_a.url)
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
      expect(base_case_a.content).to include("[[base-case.b]]")
    end

  end

  context "when certain jekyll types are excluded in configs" do
    let(:config_overrides) { { "wikilinks" => { "exclude" => ["notes", "pages", "posts"] } } }

    it "does not process [[wikilinks]] for those types" do
      expect(base_case_a.content).to include("[[base-case.b]]")
      expect(one_page.content).to include("[[base-case.a]]")
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

  context "when certain jekyll types are excluded in graph configs" do
    let(:config_overrides) { { "d3_graph_data" => { "exclude" => ["pages", "posts"] } } }
    # before(:each) do
    #   # cleanup generated assets
    #   FileUtils.rm_rf(Dir["#{fixtures_dir("/assets/graph-net-web.json")}"])
    #   # cleanup site_dir dir
    #   FileUtils.rm_rf(Dir["#{site_dir()}"])
    # end

    it "does not generate graph data for those jekyll types" do
      expect(graph_data["nodes"].find { |n| n["title"] == "One Page" }).to eql(nil)
      expect(graph_data["nodes"].find { |n| n["title"] == "One Post" }).to eql(nil)

      expect(graph_data["links"].find { |n| n["source"] == "One Page" }).to eql(nil)
      expect(graph_data["links"].find { |n| n["source"] == "One Post" }).to eql(nil)
    end

  end

  # /graph

  context "when 'baseurl' is set in configs" do
    let(:config_overrides) { { "baseurl" => "/wikilinks" } }

    it "baseurl included in href" do
      expect(base_case_a.output).to include("/wikilinks")
    end

    it "wiki-links are parsed and a element is generated" do
      expect(base_case_a.output).to eq("<p>This <a class=\"wiki-link\" href=\"/wikilinks/note/e0c824b6-0b8c-4595-8032-b6889edd815f/\">base case b</a> has a littlecar.</p>\n")
    end

  end

  context "when target [[wikilink]] note exists and contains whitespace" do
    
    it "[[wikilinks]] work as expected; full output" do
      expect(link_whitespace_in_filename.output).to eq("<p>Link to <a class=\"wiki-link\" href=\"/note/fb6bf728-948f-489e-9c9f-bb2b92677192/\">whitespace in filename</a>.</p>\n")
    end

  end

  context "when [[wikilink]]s references cross jekyll types (collection item, post, or page)" do

    it "work as expected when post targets collection item; full output" do
      expect(one_post.output).to eq("<p>Posts support links, like to <a class=\"wiki-link\" href=\"/note/8f6277a1-b63a-4ac7-902d-d17e27cb950c/\">base case a</a>.</p>\n")
    end
    
    it "work as expected when collection item targets a post; full output" do
      expect(link_to_post_note.output).to eq("<p>This note links to <a class=\"wiki-link\" href=\"/2020/12/08/one-post/\">one post</a>.</p>\n")
    end

    it "work as expected when page targets collection item; full output" do
      expect(one_page.output).to eq("<p>This page links to a <a class=\"wiki-link\" href=\"/note/8f6277a1-b63a-4ac7-902d-d17e27cb950c/\">base case a</a>.</p>\n")
    end
    
    it "work as expected when collection item targets a page; full output" do
      expect(link_to_page_note.output).to eq("<p>This note links to <a class=\"wiki-link\" href=\"/one-page/\">one page</a>.</p>\n")
    end

    # todo: collection-type-1 <-> collection-type-2
    # todo: page <-> post
  end

  context "when typed::[[wikilink]] exists" do
    
    it "inline; full output" do
      expect(typed_inline.output).to eq("<p>This link is typed inline: <a class=\"wiki-link link-type inline-typed\" href=\"/note/8f6277a1-b63a-4ac7-902d-d17e27cb950c/\">base case a</a>.</p>\n")
      # corresponding 'link_type' added to linked file
      expect(base_case_a.data).to include("link_types")
      expect(base_case_a.data['link_types']).to eq([nil, nil, nil, nil, nil, "inline-typed"])
      expect(base_case_a.data).to include("backlinks")
      expect(base_case_a.data['backlinks'][0].is_a?(Jekyll::Page)).to be true
      expect(base_case_a.data['backlinks'][1].is_a?(Jekyll::Document)).to be true
      expect(base_case_a.data['backlinks'][2].is_a?(Jekyll::Document)).to be true
      expect(base_case_a.data['backlinks'][3].is_a?(Jekyll::Document)).to be true
      expect(base_case_a.data['backlinks'][4].is_a?(Jekyll::Document)).to be true
      expect(base_case_a.data['backlinks'][5].is_a?(Jekyll::Document)).to be true # this is the corresponding typed link
    end

    it "block; full output" do
      expect(typed_block.output).to eq("<p>This link is block typed.</p>\n\n")
      expect(typed_block.data).to include("attributes")
      expect(typed_block.data['attributes'].keys).to eq(["block-typed"])
      expect(typed_block.data['attributes'].values[0].is_a?(Jekyll::Document)).to be true
    end
  
  end

  # /happy-path

  context "when target [[wikilink]] note does not exist" do
    
    it "injects a span element with descriptive title" do
      expect(missing_doc.output).to include("<span title=\"Content not found.\"")
      expect(missing_doc.output).to include("</span>")
      expect(missing_doc_many.output).to include("<span title=\"Content not found.\"").twice
      expect(missing_doc_many.output).to include("</span>").twice
    end

    it "assigns 'invalid-wiki-link' class to span element" do
      expect(missing_doc.output).to include("class=\"invalid-wiki-link\"")
      expect(missing_doc_many.output).to include("class=\"invalid-wiki-link\"").twice
    end

    it "leaves original angle brackets and text untouched" do
      expect(missing_doc.output).to include("[[no.doc]]")
      expect(missing_doc_many.output).to include("[[no.doc.1]]")
      expect(missing_doc_many.output).to include("[[no.doc.2]]")
    end

    it "full output" do
      expect(missing_doc.output).to eq("<p>This <span title=\"Content not found.\" class=\"invalid-wiki-link\">[[no.doc]]</span> has no target.</p>\n")
      expect(missing_doc_many.output).to eq("<p>This fish has no targets like <span title=\"Content not found.\" class=\"invalid-wiki-link\">[[no.doc.1]]</span> and <span title=\"Content not found.\" class=\"invalid-wiki-link\">[[no.doc.2]]</span>.</p>\n")
    end

    it "handles header url fragments; full output" do
      expect(link_header_missing_doc.output).to eq("<p>This note contains an invalid link with an invalid header <span title=\"Content not found.\" class=\"invalid-wiki-link\">[[long-note#Zero]]</span>.</p>\n")
    end

    it "generates graph data" do
      # expect(graph_generated_file.class).to be(File)
      # expect(graph_generated_file.ext).to be(".json")
      expect(graph_static_file).to be_a(Jekyll::StaticFile)
      expect(graph_static_file.relative_path).not_to be(nil)
      expect(graph_data.class).to be(Hash)
    end

    it "generated graph data contains nodes of format: { nodes: [ {id: '', url: '', label: ''}, ... ] }" do
      expect(missing_link_graph_node.keys).to include("id")
      expect(missing_link_graph_node.keys).to include("url")
      expect(missing_link_graph_node.keys).to include("label")
    end

    it "nodes' 'id's equal their url (since urls should be unique)" do
      expect(missing_link_graph_node["id"]).to eq(missing_link_graph_node["url"])
    end

    it "nodes' 'label's equal their doc title" do
      expect(missing_link_graph_node["label"]).to eq(missing_doc.data["title"])
    end

    it "nodes' 'url's equal their doc urls" do
      expect(missing_link_graph_node["url"]).to eq(missing_doc.url)
    end

    it "generated graph data contains links of format: { links: [ { source: '', target: ''}, ... ] }" do
      expect(missing_target_graph_link.keys).to include("source")
      expect(missing_target_graph_link.keys).to include("target")
    end

    it "links' missing 'target' equals the [[wikitext]] in brackets." do
      expect(missing_target_graph_link["target"]).to eq("no.doc")
    end

  end

  context "when target [[wikilink]] using piped labels exists" do

    it "renders the label text, not the note's filename" do
      expect(label.output).to include("label")
      expect(label.output).to_not include("base-case.a")
    end

    it "full output" do
      expect(label.output).to eq("<p>This doc uses a <a class=\"wiki-link\" href=\"/note/8f6277a1-b63a-4ac7-902d-d17e27cb950c/\">label</a>.</p>\n")
    end

    # labelled text preserves [square brackets]
    it "renders the label text with [square brackets], not the note's filename" do
      pending("flexible label text")
      expect(label_sq_br.output).to include("label with [square brackets]")
      expect(label_sq_br.output).to_not include("base-case.a")
    end

    it "full output" do
      pending("flexible label text")
      expect(label_sq_br.output).to eq("<p>This doc uses a <a class=\"wiki-link\" href=\"/note/8f6277a1-b63a-4ac7-902d-d17e27cb950c/\">label with [square brackets]</a>.</p>\n")
    end

    # header fragment

    it "header url fragments contain note name and header text" do
      expect(link_header_label.output).to include("labelled text")
    end

    it "header url fragment in url" do
      expect(link_header_label.output).to include("/notes/long-note/#two")
    end

    it "processes header url fragments; full output" do
      expect(link_header_label.output).to eq("<p>This note contains a link to a header with <a class=\"wiki-link\" href=\"/notes/long-note/#two\">labelled text</a>.</p>\n")
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
      expect(labelled_link_header_missing.output).to include("[[long-note#Zero|labelled text]]")
    end

    it "processes header url fragments; full output" do
      expect(labelled_link_header_missing.output).to eq("<p>This note contains an invalid link fragment to <span title=\"Content not found.\" class=\"invalid-wiki-link\">[[long-note#Zero|labelled text]]</span>.</p>\n")
    end
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
      expect(embed.output).to eq("<p>The following link should be embedded:</p>\n\n<div class=\"wiki-link-embed\"><div class=\"wiki-link-embed-title\">Base Case A</div><div class=\"wiki-link-embed-content\"><p>This <a class=\"wiki-link\" href=\"/note/e0c824b6-0b8c-4595-8032-b6889edd815f/\">base case b</a> has a littlecar.</p></div><div class=\"wiki-link-embed-link\"><a href=\"/note/8f6277a1-b63a-4ac7-902d-d17e27cb950c/\"></a></div></div>\n")
    end

    it "converts/'markdownifies' nested content'" do
      expect(embed_long.output).to include("<div class=\"wiki-link-embed-content\"><h1 id=\"one\">One</h1><ul>  <li>a</li>  <li>b</li>  <li>c    <h1 id=\"two\">Two</h1>  </li>  <li>d</li>  <li>e</li>  <li>f    <h1 id=\"three\">Three</h1>  </li>  <li>g</li>  <li>h</li>  <li>i    <h1 id=\"four\">Four</h1>  </li>  <li>This is some text to test out blocks. ^block_id</li></ul><p>Some more text to verify that block_id captures are not over-capturing.</p></div>")
    end

    it "full output; long" do
      expect(embed_long.output).to eq("<p>The following link should be embedded:</p>\n\n<div class=\"wiki-link-embed\"><div class=\"wiki-link-embed-title\">Long Note</div><div class=\"wiki-link-embed-content\"><h1 id=\"one\">One</h1><ul>  <li>a</li>  <li>b</li>  <li>c    <h1 id=\"two\">Two</h1>  </li>  <li>d</li>  <li>e</li>  <li>f    <h1 id=\"three\">Three</h1>  </li>  <li>g</li>  <li>h</li>  <li>i    <h1 id=\"four\">Four</h1>  </li>  <li>This is some text to test out blocks. ^block_id</li></ul><p>Some more text to verify that block_id captures are not over-capturing.</p></div><div class=\"wiki-link-embed-link\"><a href=\"/notes/long-note/\"></a></div></div>\n")
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
