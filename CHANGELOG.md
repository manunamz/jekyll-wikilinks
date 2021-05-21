## [0.0.3] - 2021-05-21

### Added
- `enable` config.
- `exclude` config; user may exclude jekyll types: "pages", "posts", or collection types (ex: "notes").
- d3 graph data generation for network graphs.
- `enable` config for graph data generation.
- `exclude` config for graph data generation (works similarly to above).

### Changed
- All markdown files (jekyll types: pages, posts, and collections) are processed by default.

## [0.0.2] - 2021-05-07

- Bumpbed version because yank.

## [0.0.1] - 2021-05-07

- Initial release
- A collection defined in config.yml (`wikilinks_collection: <collection-name>`) will be targetted for processing \[\[wikilinks]], which are parsed and replaced with `a` html elements with a an `href` pointing to the note's url.
