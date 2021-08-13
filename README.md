# Jekyll-Wikilinks

⚠️ This is gem is under active development! ⚠️

⚠️ Expect breaking changes and surprises until otherwise noted (likely by v0.1.0 or v1.0.0). ⚠️

## Installation

1. Add `gem 'jekyll-wikilinks'` to your site's Gemfile and run `bundle`.
2. You may edit `_config.yml` to toggle the plugin and graph generation on/off or exclude certain jekyll types. (jekyll types: `pages`, `posts`, and `collections`. [Here](https://ben.balter.com/2015/02/20/jekyll-collections/) is a blog post about them.)

Defaults look like this:

```
wikilinks:
  enabled: true
  exclude: []
```

The `enabled` flags may be toggled to turn off the plugin or turn off `d3_graph_data` generation. Any jekyll type ("pages", "posts", or collection names such as "docs" or "notes") may be added to a list of `exclude`s for either wikilinks or graph generation.

## Syntax
- File level links: `[[filename]]`
  - Wikilink text matches note filenames. (e.g. [[a-note]] -> a-note.md, [[a.note]] -> a.note.md, [[a note]] -> a note.md)
  - [[wikilink]] text is replaced with its frontmatter `title` attribute, lower-cased, when rendered.
  Case is ignored in [[WiKi LiNKs]] when matching link text to filename.
  - HTML: `<a class="wiki-link" href="doc_url">lower-cased title</a>`
- Header level links: `[[filename#header]]`
  - Internal header validation uses [`kramdown`](https://github.com/gettalong/kramdown)'s regex for header identification.
  - HTML: `<a class="wiki-link" href="doc_url">lower-cased title > header</a>`
- Block level links: `[[filename#^block_id]]`
  - Make sure the ` ^block_id` in the target document has a space before the caret ` ^`.
  - CAVEAT:
    - Since there aren't pre-existing web standards for blocks, there are some holes in this plugin's implementation. See following bullets.
    - `^block_id`s themselves are left untouched so there is a way visually to identify the block once on the page's document.
    - Blocks are treated the same way as headers, which is to say the `block_id` is appended as a url fragment (e.g. `www.blog.com/wikilink/#block_id`). With this url fragment, auto-scrolling to the corresponding html element id can be enabled. You will have to manually create those html elment ids yourself for now.
  - HTML: `<a class="wiki-link" href="doc_url">lower-cased title > ^block_id</a>`
- Embeds: `![[filename]]`
  - ⚠️ CAVEATS:
    - Wikilinks inside the embedded files are ~~not~~ processed (...but I don't quite understand why -- maybe because when you call the `markdownify` liquid tag's underlying ruby function it automatically attaches this markdown-extension-like behavior...??).
    - ⚠️ header-lvl + block-lvl embeds not yet supported
  - HTML:
    ```
      <div class="wiki-link-embed">
        <div class="wiki-link-embed-title">
          // doc title here
        </div>
        <div class="wiki-link-embed-content">
          // embed content here
        </div>
        <a class="wiki-link-embed-link" href="doc_url"></a>
      </div>
      ```
- Embedded images: `![[image.png]]`
  - Make sure to set `wiki-link-img` height and width css properties.
  - Supported formats: '.png', '.jpg', '.gif', '.psd', '.svg'
  - HTML:
    ```
      <p>
        <span class="wiki-link-embed-image">
          <img class="wiki-link-img" src="img_relative_path"/>
        </span>
      </p>
      ```
- Labelling (sometimes called 'aliasing'): `[[filename|label text]]`
  - Works for all wikilink levels:
    - `[[filename|label text]]`
    - `[[filename#header|label text]]`
    - `[[filename#^block_id|label text]]`
  - [🐛 KNOWN-BUG](https://github.com/manunamz/jekyll-wikilinks/issues/17): Square brackets currently do not work in label text (e.g. `[[filename|this [won't] work]]`).
  - HTML: `<a class="wiki-link" href="doc_url">label text</a>`
- Typed wikilinks: `link_type::[[filename]]`
  - Types should not contain whitespace. (kabob-case is recommended, but snake_case and camelCase will work too)
  - There are two types - block and inline.
  - **Block** level typed wikilinks (also called a document's 'attributes') are identiable by the fact that they are the only text on a single line. So, the example above would be prefixed with a newline `\n` before the wikilink. They are removed from the file entirely and are saved as metadata in each jekyll document.
  - **Inline** level typed wikilinks are rendered in-place like other wikilinks. They also add a `link-type` css class, as well as a css class with the name of the link type.
  - HTML: `<a class="wiki-link link-type link_type">lower-cased title</a>`
- Embedded Typed wikilinks: `!link_type::[[filename]]`
    - CAVEATS: ⚠️ Link type information is currently unused.
    - HTML: Same as embed HTML format above.

### MetaData
The following metadata are stored as frontmatter variables and are accessible in liquid templates:

- `attributed` (block-level typed baclinks)
- `attributes` (block-level typed forelinks)
- `backlinks`
- `forelinks` ('forward' links)

All metadata are arrays of hashes with key values `type` and `doc`. `type` retrieves a string that is the link type's name and `doc` retrieves the linked jekyll document.

```
<!-- render as 👉 "link-type: title" -->

{{ backlink.type }}: <a class="wiki-link" href="{{ backlink.doc.url }}">{{backlink.doc.title}}</a>
```

### Liquid Template Filter
There are two types of liquid filters provided: One for jekyll document types and one for link types.

Say you want to display 'post' backlinks and 'note' backlinks separately. Just filter any of the attribute or link metadata like so:

```
<!-- show post backlink titles -->
{% assign post_backlinks = page.backlinks | doc_type: "posts" %}
{% for backlink in post_backlinks %}
  {{ backlink.doc.title }}
{% endfor %}

<!-- show note backlink titles -->
{% assign note_backlinks = page.backlinks | doc_type: "notes" %}
{% for backlink in note_backlinks %}
  {{ backlink.doc.title }}
{% endfor %}
```

The same setup works for link types:

```
<!-- show note backlink titles -->
{% assign backlinks_authored_by_me = page.backlinks | link_type: "by_me" %}
{% for backlink in backlinks_authored_by_me %}
  {{ backlink.doc.title }}
{% endfor %}
```

### D3 Graph Data
Graph data is generated and output to a `.json` file in your `/assets` directory in the following format:

```
{
  "nodes": [
    {
      "id": "<some-id>",
      "url": "<relative-url>",
      "label": "<note's-title>",
    },
    ...
  ],
  "links": [
    {
      "source": "<a-node-id>",
      "target": "<another-node-id>",
    },
    ...
  ]
}
```

`links` are built from `backlinks` and `attributed`.

I've created a gist [here](https://gist.github.com/manunamz/3222e73c6b7eaef3a677a26e8f177466) of a working network graph using d3 version 6. You can see in action [here](https://manunamz.github.io/jekyll-bonsai/) (just click the 🕸 in the top-left to toggle it on).

---

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

A note on testing -- all tests pass if they are run in certain orders. As far as I can tell, this is due to quirks in setup/teardown of tests _not_ the plugin itself. This will be addressed soon, just know if your tests fail you might just need to re-run them in a different order and they will pass.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/manunamz/jekyll-wikilinks.

## Influences
- [A pure liquid impl](https://github.com/jhvanderschee/brackettest)
- [use ruby classes more fully](https://github.com/benbalter/jekyll-relative-links)
- Referenced [digital garden jekyll template](https://github.com/maximevaillancourt/digital-garden-jekyll-template).
- [regex ref](https://github.com/kortina/vscode-markdown-notes/blob/0ac9205ea909511b708d45cbca39c880688b5969/syntaxes/notes.tmLanguage.json)
- [converterible example](https://github.com/metala/jekyll-wikilinks-plugin/blob/master/wikilinks.rb)
- [github wiki](https://docs.github.com/en/communities/documenting-your-project-with-wikis/editing-wiki-content)
## The Prior State of Wikilinks Support For Jekyll
- They are supported by [md4c](https://github.com/mity/md4c#markdown-extensions) (see `MD_FLAG_WIKILINKS`).
- They are not supported by [kramdown](https://github.com/gettalong/kramdown) (searched 'wikilinks' in repo).
- They are [not supported](https://github.com/gjtorikian/commonmarker#options) by [`jekyll-commonmark`](https://github.com/jekyll/jekyll-commonmark) that I can see (don't see any reference to `MD_FLAG_WIKILINKS`).
- There are scattered ruby/jekyll implementations around the internet: [here](https://github.com/maximevaillancourt/digital-garden-jekyll-template/blob/master/_plugins/bidirectional_links_generator.rb), [here](https://github.com/metala/jekyll-wikilinks-plugin/blob/master/wikilinks.rb), are some examples.
- Stackoverflow [sees lots of interest in this functionality](https://stackoverflow.com/questions/4629675/jekyll-markdown-internal-links), specifically for jekyll, but no other answers lead to a plugin like this one. (But who knows...SO deleted my answer pointing to this plugin 👻)
