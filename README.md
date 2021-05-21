# Jekyll-Wikilinks

## Installation

1. Add `gem 'jekyll-wikilinks'` to your site's Gemfile and run `bundle`.
2. You may edit `_config.yml` to toggle the plugin and graph generation on/off or exclude certain jekyll types. Defaults look like this:

```
wikilinks:
  enable: true
  exclude: []
d3_graph_data:
  enabled: true
  exclude: []
```

The `enable` flags may be toggled to turn off the plugin or turn off d3_graph_data generation. Any jekyll type ("pages", "posts", or collection names such as "notes") may be added to a list of `exclude`s for either wikilinks or graph generation.

## Notable Usage Details

### Wikilink Syntax
- [[wikilink]] text is replaced with its `title` attribute, lower-cased, in its frontmatter when rendered.
- [[wikilinks]] matches note filenames. (e.g. [[a-note]] -> a-note.md, [[a.note.md]] -> a.note.md, [[a note]] -> a note.md).
  - Case is ignored in [[WiKi LiNKs]] when matching link text to filename.
- aliasing in both directions is supported:
  - [[some text|filename]]
  - [[filename|some text]]

### MetaData
Each item will have a `backlinks` metadata field added to its data/frontmatter. You can then access the entire document of each backlink item from that field. 

### Liquid Template Filter
Since all documents are processed, it may be useful to filter backlinks based on their jekyll type, as they may not share all the same attributes. So, there is a liquid template filter provided for that purpose. For example, say you want to display 'post' backlinks and 'note' backlinks separately. Just filter the `backlinks` metadata like so:

```
<!-- show post backlink titles -->
{% assign post_backlinks = page.backlinks | backlink_type: "posts" %}
{% for backlink in post_backlinks %}
  {{ backlink.title }}
{% endfor %}
<!-- show note backlink titles -->
{% assign note_backlinks = page.backlinks | backlink_type: "notes" %}
{% for backlink in note_backlinks %}
  {{ backlink.title }}
{% endfor %}
```

### D3 Graph Data
Graph data is generated and output to a `.json` file in your `/assets` directory in the following format:

```
{
  "nodes": ["id": "<some-id>", "url": "<relative-url>", "label": "<note's-title>"],
  "links": ["source": "<a-node-id>", "target": "<another-node-id>"]
}
```

D3 can be tricky, so I've created a gist [here](https://gist.github.com/shorty25h0r7/3222e73c6b7eaef3a677a26e8f177466) of a network graph using d3 version 6. You can see in action [here](https://shorty25h0r7.github.io/jekyll-bonsai/) (just click the 🕸 in the top-left to toggle it on).

---

## Influences
- [A pure liquid impl](https://github.com/jhvanderschee/brackettest)
- [use ruby classes more fully](https://github.com/benbalter/jekyll-relative-links)
- Backlinks generator from [digital garden jekyll template](https://github.com/maximevaillancourt/digital-garden-jekyll-template).
- [regex ref](https://github.com/kortina/vscode-markdown-notes/blob/0ac9205ea909511b708d45cbca39c880688b5969/syntaxes/notes.tmLanguage.json)
- [converterible example](https://github.com/metala/jekyll-wikilinks-plugin/blob/master/wikilinks.rb)
- [github wiki](https://docs.github.com/en/communities/documenting-your-project-with-wikis/editing-wiki-content)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

A note on testing -- all tests pass if they are run in certain orders. As far as I can tell, this is due to quirks in setup/teardown of tests _not_ the plugin itself. This will be addressed soon, just know if your tests fail you might just need to re-run them in a different order and they will pass.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/shorty25h0r7/jekyll-wikilinks.

## I am Not Reduplicating Work Due-Diligence
- Wikilinks are part of the [commonmark spec](https://github.com/mity/md4c#markdown-extensions) (see `MD_FLAG_WIKILINKS`).
- They are not supported by [kramdown](https://github.com/gettalong/kramdown) (searched 'wikilinks' in repo).
- They are [not supported](https://github.com/gjtorikian/commonmarker#options) by [`jekyll-commonmark`](https://github.com/jekyll/jekyll-commonmark) that I can see (don't see any reference to `MD_FLAG_WIKILINKS`).
- There are scattered implementations around the internet: [here](https://github.com/maximevaillancourt/digital-garden-jekyll-template/blob/master/_plugins/bidirectional_links_generator.rb), [here](https://github.com/metala/jekyll-wikilinks-plugin/blob/master/wikilinks.rb), are some examples.
- Stackoverflow [sees lots of interest in this functionality](https://stackoverflow.com/questions/4629675/jekyll-markdown-internal-links), specifically for jekyll, but no other answers lead to a plugin like this one. (But who knows...SO deleted my answer pointing to this plugin 👻)
