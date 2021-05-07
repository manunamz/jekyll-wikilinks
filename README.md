# Jekyll-Wikilinks

## Installation

1. Add `gem 'jekyll-wikilinks'` to your site's Gemfile and run `bundle`.
2. Add the following to your `_config.yml`:

```
wikilinks_collection: "<collection-name>"
```

3. Ensure note frontmatter contains a `title` and a `permalink`.

## Notable
- [[wikilinks]] matches note filenames. (e.g. [[a-note]] -> a-note.md, [[a.note.md]] -> a.note.md, [[a note]] -> a note.md).
- [[wikilink]] text is replaced with its `title` attribute, lower-cased, in its frontmatter when rendered.
- Case is ignored in [[WiKi LiNKs]] when matching link text to filename.

## Future Features
- Support wikilinks across multiple collections and posts.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/shorty25h0r7/jekyll-wikilinks.
