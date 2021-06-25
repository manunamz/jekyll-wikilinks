## [0.0.4] - 2021-06-23
### Added
- Syntax:
  - Header level wikilinks: `[[filename#header txt]]`
  - Block level wikilinks: `[[filename#^block_id]]`
  - Labelling support for new wikilink levels.
  - Single file embeds (without internal wikilink processing): `![[filename]]`
  - Image embeds: `![[image.png]]`
  - Typed wikilinks: `link-type::[[filename]]`
    - Two types: block-level and inline-level.
    - Works for all wikilink levels.
  - Embedded typed wikilinks: `!link-type::[[filename]]`
- Metadata:
  - `attributed` (block-level typed backlinks)
  - `attributes` (block-level typed forelinks)
  - `forelinks` ('forward' links)
- Configs:
  - `assets_rel_path`: Set custom assets relative path location in project.
### Changed
- Metadata:
  - ⚠️ `backlinks`: array -> hash with keys `types` and `doc`.
### Removed
- ❗️ Left-side labelling/aliasing.
## [0.0.3] - 2021-05-21

### Added
- `enable` config.
- `exclude` config; user may exclude jekyll types: "pages", "posts", or collection types (ex: "notes").
- d3 graph data generation for network graphs.
- `enable` config for graph data generation.
- `exclude` config for graph data generation (works similarly to above).
- `backlinks` metadata added to each item processed.
- `backlink_type` liquid template filter added.

### Changed
- All markdown files (jekyll types: pages, posts, and collections) are processed by default.

## [0.0.2] - 2021-05-07

- Bumpbed version because yank.

## [0.0.1] - 2021-05-07

- Initial release
- A collection defined in config.yml (`wikilinks_collection: <collection-name>`) will be targetted for processing \[\[wikilinks]], which are parsed and replaced with `a` html elements with a an `href` pointing to the note's url.
