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

  # let(:typed_block_many)                { find_by_title(site.collections["docs"].docs, "Typed Link Block Many") }
  # let(:typed_block_list_many)           { find_by_title(site.collections["docs"].docs, "Typed Link Block List Many") }

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

  # context "when there are multiple block style typed::[[wikilink]]s" do
  #
  #   context "metadata:" do
  #
  #     it "'attributes' added to original document" do
  #       expect(typed_block_many.data.keys).to include("attributes")
  #     end
  #
  #     it "'attributed' added to linked documents" do
  #       expect(base_case_a.data.keys).to include('attributed')
  #       expect(base_case_b.data.keys).to include('attributed')
  #     end
  #
  #   end
  #
  #
  #   context "relationships" do
  #
  #     it "'attributes' in original doc contain linked doc data" do
  #       expect(typed_block_many['attributes']).to eq([
  #         {"type"=>"many-block-typed", "urls"=>["/doc/8f6277a1-b63a-4ac7-902d-d17e27cb950c/"]},
  #         {"type"=>"many-block-typed", "urls"=>["/doc/e0c824b6-0b8c-4595-8032-b6889edd815f/"]},
  #       ])
  #     end
  #
  #     it "'attributed' in first linked doc contains original doc data; full content" do
  #       expect(base_case_a.data['attributed']).to include(
  #         {"type"=>"many-block-typed", "urls"=>["/docs/typed.block.many/"]},
  #       )
  #     end
  #
  #     it "'attributed' in second linked doc contains original doc data; full content" do
  #       expect(base_case_b.data['attributed']).to include(
  #         {"type"=>"many-block-typed", "urls"=>["/docs/typed.block.many/"]},
  #       )
  #     end
  #
  #   end
  #
  # end
  #
  # context "when typed::[[wikilink]] block list exists" do
  #
  #   it "links are not rendered" do
  #     expect(typed_block_list_many.output).to eq("\n<p>Add multiple block level typed wikilinks to create wikipedia-style infoboxes!</p>\n")
  #   end
  #
  #   context "metadata:" do
  #
  #     context "'attributed'" do
  #
  #       it "added to linked document" do
  #         expect(base_case_a.data.keys).to include('attributed')
  #       end
  #
  #       it "contains original doc data; full content" do
  #         expect(base_case_a.data['attributed']).to eq([
  #           {"type"=>"many-block-typed", "urls"=>["/docs/typed.block.many/"]},
  #           {"type"=>"block-typed", "urls"=>["/docs/typed.block/"]},
  #         ])
  #       end
  #
  #     end
  #
  #     context "'attributes'" do
  #
  #       it "added to original document" do
  #         expect(typed_block_list_many.data.keys).to include("attributes")
  #       end
  #
  #       it "contains linked doc data; full content" do
  #         expect(typed_block_list_many.data['attributes']).to eq(
  #           [{"type"=>"block-typed-list-dash",
  #             "urls"=>["/docs/block.a/", "/docs/block.b/"]},
  #            {"type"=>"block-typed-list-star",
  #             "urls"=>["/docs/block.a/", "/docs/block.b/"]},
  #            {"type"=>"block-typed-list-plus",
  #             "urls"=>["/docs/block.a/", "/docs/block.b/"]},
  #           {"type"=>"block-typed-list-comma",
  #             "urls"=>["/docs/block.a/", "/docs/block.b/"]},
  #           {"type"=>"block-typed-list-comma-ws",
  #             "urls"=>["/docs/block.a/", "/docs/block.b/"]},
  #           {"type"=>"block-typed-list-ws-comma-ws",
  #             "urls"=>["/docs/block.a/", "/docs/block.b/"]},
  #         ])
  #       end
  #
  #     end
  #
  #   end
  #
  # end

end
