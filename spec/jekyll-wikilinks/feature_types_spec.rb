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

  context "when inline style typed::[[wikilink]] exists" do

    context "metadata:" do

      context "'backlinks'" do

        it "added to linked document" do
          expect(base_case_a.data.keys).to include("backlinks")
        end

        it "contains linked doc info; full content" do
          expect(base_case_a.data['backlinks']).to include({"url"=>"/docs/typed.inline/", "type"=>"inline-typed"})
        end

      end

      context "'forelinks'" do

        it "added to original document" do
          expect(typed_inline.data.keys).to include("attributes")
        end

        it "contains linked doc info; full content" do
          expect(typed_inline.data['forelinks']).to include({"url"=>"/doc/8f6277a1-b63a-4ac7-902d-d17e27cb950c/", "type"=>"inline-typed"})
        end

      end

    end

  end

end
