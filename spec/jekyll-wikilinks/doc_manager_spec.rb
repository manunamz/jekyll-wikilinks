# # frozen_string_literal: true
#
# require "jekyll-wikilinks"
# require "spec_helper"
# require "shared_context"
#
# RSpec.describe(Jekyll::WikiLinks::DocManager) do
#   include_context "shared jekyll configs"
#   let(:config_overrides) { {} }
#   let(:site)                            { Jekyll::Site.new(config) }
#
#   # makes markdown tests work
#   subject { described_class.new(site.config) }
#
#   before(:each) do
#     site.reset
#     site.process
#   end
#
#   after(:each) do
#     # cleanup _site/ dir
#     FileUtils.rm_rf(Dir["#{site_dir()}"])
#   end
#
#   context "processes markdown" do
#
#     context "detecting markdown" do
#       before { subject.instance_variable_set "@site", site }
#
#       it "knows when an extension is markdown" do
#         expect(subject.send(:markdown_extension?, ".md")).to eql(true)
#       end
#
#       it "knows when an extension isn't markdown" do
#         expect(subject.send(:markdown_extension?, ".html")).to eql(false)
#       end
#
#       it "knows the markdown converter" do
#         expect(subject.send(:markdown_converter)).to be_a(Jekyll::Converters::Markdown)
#       end
#     end
#
#   end
# end
