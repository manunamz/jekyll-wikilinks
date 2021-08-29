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

  let(:typed_block)                     { find_by_title(site.collections["docs"].docs, "Typed Link Block") }
  let(:typed_block_many)                { find_by_title(site.collections["docs"].docs, "Typed Link Block Many") }
  let(:typed_block_list_many)           { find_by_title(site.collections["docs"].docs, "Typed Link Block List Many") }

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

  context "when block style typed::[[wikilink]] exists" do

    context "metadata:" do

      context "'attributed'" do

        it "added to linked document" do
          expect(base_case_a.data.keys).to include('attributed')
        end

        it "contains original doc data; full content" do
          expect(base_case_a.data['attributed']).to eq([
            {"type"=>"many-block-typed", "urls"=>["/docs/typed.block.many/"]},
            {"type"=>"block-typed", "urls"=>["/docs/typed.block/"]},
          ])
        end

      end

      context "'attributes'" do

        it "added to original document" do
          expect(typed_block.data.keys).to include("attributes")
        end

        it "contains linked doc data; full content" do
          expect(typed_block.data['attributes']).to eq([
            {"type"=>"block-typed", "urls"=>["/doc/8f6277a1-b63a-4ac7-902d-d17e27cb950c/"]}
          ])
        end

      end

    end

  end

  context "when there are multiple block style typed::[[wikilink]]s" do

    context "metadata:" do

      it "'attributes' added to original document" do
        expect(typed_block_many.data.keys).to include("attributes")
      end

      it "'attributed' added to linked documents" do
        expect(base_case_a.data.keys).to include('attributed')
        expect(base_case_b.data.keys).to include('attributed')
      end

    end


    context "relationships" do

      it "'attributes' in original doc contain linked doc data" do
        expect(typed_block_many['attributes']).to eq([
          {"type"=>"many-block-typed", "urls"=>["/doc/8f6277a1-b63a-4ac7-902d-d17e27cb950c/"]},
          {"type"=>"many-block-typed", "urls"=>["/doc/e0c824b6-0b8c-4595-8032-b6889edd815f/"]},
        ])
      end

      it "'attributed' in first linked doc contains original doc data; full content" do
        expect(base_case_a.data['attributed']).to include(
          {"type"=>"many-block-typed", "urls"=>["/docs/typed.block.many/"]},
        )
      end

      it "'attributed' in second linked doc contains original doc data; full content" do
        expect(base_case_b.data['attributed']).to include(
          {"type"=>"many-block-typed", "urls"=>["/docs/typed.block.many/"]},
        )
      end

    end

  end

  context "when typed::[[wikilink]] block list exists" do

    it "links are not rendered" do
      expect(typed_block_list_many.output).to eq("\n<p>Add multiple block level typed wikilinks to create wikipedia-style infoboxes!</p>\n")
    end

    context "metadata:" do

      context "'attributed'" do

        it "added to linked document" do
          expect(base_case_a.data.keys).to include('attributed')
        end

        it "contains original doc data; full content" do
          expect(base_case_a.data['attributed']).to eq([
            {"type"=>"many-block-typed", "urls"=>["/docs/typed.block.many/"]},
            {"type"=>"block-typed", "urls"=>["/docs/typed.block/"]},
          ])
        end

      end

      context "'attributes'" do

        it "added to original document" do
          expect(typed_block_list_many.data.keys).to include("attributes")
        end

        it "contains linked doc data; full content" do
          expect(typed_block_list_many.data['attributes']).to eq(
            [{"type"=>"block-typed-list-dash",
              "urls"=>["/docs/block.a/", "/docs/block.b/"]},
             {"type"=>"block-typed-list-star",
              "urls"=>["/docs/block.a/", "/docs/block.b/"]},
             {"type"=>"block-typed-list-plus",
              "urls"=>["/docs/block.a/", "/docs/block.b/"]},
            {"type"=>"block-typed-list-comma",
              "urls"=>["/docs/block.a/", "/docs/block.b/"]},
          ])
        end

      end

    end

  end

end
