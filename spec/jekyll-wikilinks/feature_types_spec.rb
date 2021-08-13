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

  let(:typed_inline)                    { find_by_title(site.collections["docs"].docs, "Typed Link Inline") }
  let(:typed_block)                     { find_by_title(site.collections["docs"].docs, "Typed Link Block") }
  let(:typed_block_many)                { find_by_title(site.collections["docs"].docs, "Typed Link Block Many") }

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

        it "contains original doc data" do
          expect(base_case_a.data['attributed']).to eq([
            {"doc_url"=>"/docs/typed.block.many/", "type"=>"many-block-typed"},
            {"doc_url"=>"/docs/typed.block/", "type"=>"block-typed"}]
           )
        end

      end

      context "'attributes'" do

        it "added to original document" do
          expect(typed_block.data.keys).to include("attributes")
        end

        it "contains linked doc data" do
          expect(typed_block.data['attributes']).to eq([
            {"doc_url"=>"/doc/8f6277a1-b63a-4ac7-902d-d17e27cb950c/", "type"=>"block-typed"}
          ])
        end

      end

    end

  end


  context "when inline style typed::[[wikilink]] exists" do

    context "metadata:" do

      context "'backlinks'" do

        it "added to linked document" do
          expect(base_case_a.data.keys).to include("backlinks")
        end

        it "contains linked doc info" do
          expect(base_case_a.data['backlinks']).to include({"doc_url"=>"/docs/typed.inline/", "type"=>"inline-typed"})
        end

      end

      context "'forelinks'" do

        it "added to original document" do
          expect(typed_inline.data.keys).to include("attributes")
        end

        it "contains linked doc info" do
          expect(typed_inline.data['forelinks']).to include({"doc_url"=>"/doc/8f6277a1-b63a-4ac7-902d-d17e27cb950c/", "type"=>"inline-typed"})
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
          {"doc_url"=>"/doc/8f6277a1-b63a-4ac7-902d-d17e27cb950c/", "type"=>"many-block-typed"},
          {"doc_url"=>"/doc/e0c824b6-0b8c-4595-8032-b6889edd815f/", "type"=>"many-block-typed"}
        ])
      end

      it "'attributed' in first linked doc contains original doc data" do
        expect(base_case_a.data['attributed']).to include(
          {"doc_url"=>"/docs/typed.block.many/", "type"=>"many-block-typed"}
          )
      end

      it "'attributed' in second linked doc contains original doc data" do
        expect(base_case_b.data['attributed']).to include(
          {"doc_url"=>"/docs/typed.block.many/", "type"=>"many-block-typed"}
          )
      end

    end

  end

end
