# Jekyll-Wikilinks

I was very excited to publish my first gem, but of course, it happened. Check [this post](https://github.com/jhvanderschee/brackettest) and see if it's not a better solution for you.

## Installation

1. Add `gem 'jekyll-wikilinks'` to your site's Gemfile and run `bundle`.
2. Add the following to your `_config.yml`:

```
wikilinks:
	enable: true
	exclude: []
d3_graph_data:
	enabled: true
	exclude: []
```

pages, posts, <collection-name>.

## Notable Usage Details
- scans all post, page, and collection markdown files for [[wikilinks]].
- [[wikilink]] text is replaced with its `title` attribute, lower-cased, in its frontmatter when rendered.
- [[wikilinks]] matches note filenames. (e.g. [[a-note]] -> a-note.md, [[a.note.md]] -> a.note.md, [[a note]] -> a note.md).
  - Case is ignored in [[WiKi LiNKs]] when matching link text to filename.
- aliasing in both directions is supported:
  - [[some text|filename]]
  - [[filename|some text]]

## Note
- Implementation originally adapted from [digital garden jekyll template](https://github.com/maximevaillancourt/digital-garden-jekyll-template/blob/master/_plugins/bidirectional_links_generator.rb).

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/shorty25h0r7/jekyll-wikilinks.

## I am Not Reduplicating Work Due-Diligence
- Wikilinks are part of the [commonmark spec](https://github.com/mity/md4c#markdown-extensions) (see `MD_FLAG_WIKILINKS`).
- They are not supported by [kramdown](https://github.com/gettalong/kramdown) (searched 'wikilinks' in repo).
- They are [not supported](https://github.com/gjtorikian/commonmarker#options) by [`jekyll-commonmark`](https://github.com/jekyll/jekyll-commonmark) that I can see (don't see any reference to `MD_FLAG_WIKILINKS`).
- There are scattered implementations around the internet [here](https://github.com/maximevaillancourt/digital-garden-jekyll-template/blob/master/_plugins/bidirectional_links_generator.rb), [here](https://github.com/metala/jekyll-wikilinks-plugin/blob/master/wikilinks.rb), are some examples.
- Stackoverflow [sees lots of interest in this functionality](https://stackoverflow.com/questions/4629675/jekyll-markdown-internal-links), specifically for jekyll, but has no other answers lead to a plugin like this one.
