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
        "testing"              => true,
        # "baseurl"              => "",
      )
    )
  end
  let(:site)                            { Jekyll::Site.new(config) }
  
  let(:base_case_a)                     { find_by_title(site.collections["docs"].docs, "Base Case A") }
  let(:missing_doc)                     { find_by_title(site.collections["docs"].docs, "Missing Doc") }

  let(:graph_data)                      { static_graph_file_content() }
  let(:graph_generated_file)            { find_generated_file("/assets/graph-net-web.json") }
  let(:graph_static_file)               { find_static_file("/assets/graph-net-web.json") }
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

  after(:each) do
    # cleanup generated assets
    FileUtils.rm_rf(Dir["#{fixtures_dir("/assets/graph-net-web.json")}"])
    # cleanup _site/ dir
    FileUtils.rm_rf(Dir["#{site_dir()}"])
  end

  context "when target [[wikilink]] doc exists" do

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
      expect(graph_link["target"]).to eq("/doc/e0c824b6-0b8c-4595-8032-b6889edd815f/")
    end

  end

  context "when target [[wikilink]] doc does not exist" do

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
end