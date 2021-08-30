# frozen_string_literal: true

require "jekyll-wikilinks"
require "spec_helper"
require "shared_context"

RSpec.describe(Jekyll::WikiLinks::Generator) do
  include_context "shared jekyll configs"

  let(:config_overrides)              { { "collections" => { "block_single" => { "output" => true }, "target" => { "output" => true } } } }
  let(:site)                          { Jekyll::Site.new(config) }

  # links
  let(:link)                          { find_by_title(site.collections["block_single"].docs, "Block Single Link") }
  # targets
  let(:blank_a)                       { find_by_title(site.collections["target"].docs, "Blank A") }

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

  context "BLOCK SINGLE [[wikilinks]]" do

    context "when target doc exists" do

      it "links are removed from html output" do
        expect(link.output).to_not include("block-single::[[blank.a]]")
        expect(link.output).to eq("<p>This doc contains a wikilink to a block…</p>\n\n<p>…link.</p>\n")
      end

      context "metadata:" do

        context "'attributed'" do

          it "not added to document" do
            expect(link.data['attributed']).to eq([])
          end

          it "added to linked document" do
            expect(blank_a.data.keys).to include('attributed')
          end

          it "contains original doc data; full content" do
            expect(blank_a.data['attributed']).to eq([
              {"type"=>"block-single", "urls"=>["/block_single/link/"]},
            ])
          end

          it "contain array of hashes with keys 'type' and 'urls'" do
            expect(blank_a.data['attributed']).to be_a(Array)
            expect(blank_a.data['attributed'][0].keys).to eq([ "type", "urls" ])
          end

          it "'type' is the type:: text" do
            expect(blank_a.data['attributed'][0]['type']).to eq("block-single")
          end

          it "'urls' is a url str" do
            expect(blank_a.data['attributed'][0]['urls']).to eq(["/block_single/link/"])
          end

        end

        context "'attributes'" do

          it "added to original document" do
            expect(link.data.keys).to include("attributes")
          end

          it "contains linked doc data; full content" do
            expect(link.data['attributes']).to eq([
              {"type"=>"block-single", "urls"=>["/target/blank.a/"]}
            ])
          end

          it "contain array of hashes with keys 'type' and 'urls'" do
            expect(link.data['attributes']).to be_a(Array)
            expect(link.data['attributes'][0].keys).to eq([ "type", "urls" ])
          end

          it "'type' is the type:: text" do
            expect(link.data['attributes'][0]['type']).to eq("block-single")
          end

          it "'urls' is a url str" do
            expect(link.data['attributes'][0]['urls']).to eq(["/target/blank.a/"])
          end

          it "not added to linked document" do
            expect(blank_a.data['attributes']).to eq([])
          end

        end

      end

    end

  end

end
