# frozen_string_literal: true

require "jekyll-wikilinks"
require "spec_helper"
require "shared_context"

RSpec.describe(Jekyll::WikiLinks::Generator) do
  include_context "shared jekyll configs"

  let(:config_overrides)              { { "collections" => { "target" => { "output" => true } } } }
  let(:site)                          { Jekyll::Site.new(config) }

  # links
  let(:links)                          { find_by_title(site.pages, "Mixed Links") }
  # targets
  let(:blank_c)                       { find_by_title(site.collections["target"].docs, "Blank C") }

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

  context "MIXED [[wikilinks]]" do

    context "when target doc exists" do

      context "html output" do

        it "full" do
          expect(links.output).to eq("<p>Here’s an untyped link <a class=\"wiki-link\" href=\"/target/blank.c/\">blank c</a>.</p>\n\n<p>Then an <a class=\"wiki-link typed inline-typed\" href=\"/target/blank.c/\">blank c</a>.</p>\n\n<p>Then an invalid <span class=\"invalid-wiki-link\">[[blank.not.c]]</span>.</p>\n\n<p>Then an <span class=\"invalid-wiki-link\">invalid-typed::<span class=\"invalid-wiki-link\">[[blank.not.c]]</span></span>.</p>\n")
          expect(blank_c.output).to eq("\n")
        end

      end

      context "metadata:" do

        context "'attributed'" do

          it "not added to document" do
            expect(links.data['attributed']).to eq([])
          end

          it "added to linked document" do
            expect(blank_c.data.keys).to include('attributed')
          end

        end
        
        context "'attributes'" do

          it "added to original document" do
            expect(links.data.keys).to include("attributes")
          end

          it "contains linked doc data; full content" do
            expect(links.data['attributes']).to eq([
              {"type"=>"block", "urls"=>["/target/blank.c/"]}
            ])
          end

          it "not added to linked document" do
            expect(blank_c.data['attributes']).to eq([])
          end

        end

        context "'backlinks'" do

          it "not added to original document" do
            expect(links.data['backlinks']).to eq([])
          end

          it "is added to linked document" do
            expect(blank_c.data['backlinks']).to_not eq([])
          end

          it "contain array of hashes with keys 'type' and 'url'" do
            expect(blank_c.data['backlinks']).to be_a(Array)
            expect(blank_c.data['backlinks'][0].keys).to eq([ "type", "url" ])
          end

          it "'type' is 'inline-typed'" do
            expect(blank_c.data['backlinks'][0]['type']).to eq("inline-typed")
          end

          it "'url' is a url str" do
            expect(blank_c.data['backlinks'][0]['url']).to eq("/mixed/")
          end

        end

        context "'forelinks'" do

          it "is added to document" do
            expect(links.data['forelinks']).to_not eq([])
          end

          it "contain array of hashes with keys 'type' and 'url'" do
            expect(links.data['forelinks']).to be_a(Array)
            expect(links.data['forelinks'][0].keys).to eq([ "type", "url" ])
          end

          it "not added to linked document" do
            expect(blank_c.data['forelinks']).to eq([])
          end

        end

      end

    end

  end

end
