# Jekyll-Wikilinks

## ⚠️ As of v0.0.13, this plugin has moved to [`jekyll-wikirefs`](https://github.com/wikibonsai/jekyll-wikirefs)

Jekyll-Wikilinks adds wikilinking (the ability to reference local documents via the double square bracket syntax -- [[like this]]) support to jekyll -- and more.

This gem works in conjunction with [`jekyll-graph`](https://github.com/manunamz/jekyll-graph).

This gem is part of the [jekyll-bonsai](https://jekyll-bonsai.netlify.app/) project. 🎋

## Installation

Follow the instructions for installing a [jekyll plugin](https://jekyllrb.com/docs/plugins/installation/) for `jekyll-wikilinks`.

## Configuration

Defaults look like this:

```yaml
wikilinks:
  attributes:
    enabled: true
  css:
    exclude: []
    name:
      typed: 'typed'
      wiki: 'wiki-link'
      web: 'web-link'
      invalid_wiki: 'invalid-wiki-link'
      embed_container: 'embed-container'
      embed_title: 'embed-title'
      embed_content: 'embed-content'
      embed_link: 'embed-wiki-link'
      embed_image_container: 'embed-image-container'
      embed_image: 'embed-image'
  enabled: true
  exclude: []
```

`attributes`: Toggles on/off attributes and block level wikilinks. If turned off the `attributes` meta data will not be added to each document and block level wikilinks will not be removed from the content of the document.

`css_names`: Customiztable css class names.

`css.exclude`: Defines a list of css classes that should not have the `wiki` or `web` css classes added to it.

- This is useful when there are other internal links that should not have the `web-link` css class added to it. For example, `kramdown` adds `footnote` and `reversefootnote` css classes to `a` elements that are footnotes. Since they are links internal to the site, they won't have `wiki-link`s added to them, but it is likely undesirable to have `web-link` added to these elements. This makes them good candidates to exclude from the plugin's css processing altogether and style those classes separately.

`enabled`: Toggle to turn off the plugin or turn off.

`exclude`: Any jekyll type (`pages`, `posts`, or `collections` by name) may be added to a list of excluded documents to not be processed by the jekyll-wikilinks plugin.

## Syntax

### Inline Untyped File Level Wikilinks
```markdown
[[filename]]
```
This link will match a markdown document anywhere in the jekyll project so long as it is named `filename.md`. Filenames must be unique, whitespace is allowed, and case is ignored.  The file's `title` frontmatter attribute is what gets rendered a the `a` tag's inner text.

Resulting HTML:
```html
<a class="wiki-link" href="url">lower-cased frontmatter title attribute</a>
```

### Inline Typed File Level Wikilinks
```markdown
link_type::[[filename]]
```
Types should not contain whitespace. (kabob-case is recommended, but snake_case and camelCase will work too)

These wikilinks rendered in-place like untyped wikilinks. They also add a `typed` css class, as well as a css class with the name of the given link type.

Resulting HTML:
```html
<a class="wiki-link typed link_type" href="url">lower-cased frontmatter title attribute</a>
```

### Block (Typed) Wikilinks
Also called a document's `attributes`, block wikilinks are typed wikilinks that are the only text on a single line:

```
link_type::[[filename]]

Some more text.
```

Lists are also supported and may be defined by comma-separation or markdown lists (make sure bullet type matches for all items; e.g. all items use +'s, -'s or *'s):

```
link_type::[[file-1]], [[file-2]], [[file-3]]

link_type::
- [[file-1]]
- [[file-2]]
- [[file-3]]

link_type::
+ [[file-1]]
+ [[file-2]]
+ [[file-3]]

link_type::
* [[file-1]]
* [[file-2]]
* [[file-3]]
```

These wikilinks are removed from the file entirely and their corresponding document urls and link types are saved in the `attributes` frontmatter variable of the current document and the `attributed` frontmatter variable of the linked documents.

The removal of these wikilink types is useful in the scenario where creating some form of infobox that is separate from the file's main content is desired.

Block wikilinks only work on the file-level and do not support labels or embedding. They may be toggled off in the configuration by setting: 

```
wikilinks:
  attributes: 
    enabled: false
```

---

### Header Level Wikilinks
```markdown
[[filename#header]]
```
This link will search for a file named `filename.md` and link to its `# header` if it has one. If no such header exists, the resulting `a` tag  will be rendered with the `invalid-wiki-link` css class.

Resulting HTML:
```html
<a class="wiki-link" href="url#sluggified-header-id">lower-cased frontmatter title > header</a>
```

### Block Level Wikilinks
```markdown
[[filename#^block_id]]
```

Resulting HTML:
```html
<a class="wiki-link" href="url#block_id">lower-cased title > ^block_id</a>
```
- Make sure the ` ^block_id` in the target document has a space before the caret ` ^`.
- CAVEAT:
  - `^block_id`s themselves are left untouched so there is a way visually to identify the block once on the page's document.
  - Blocks are treated the same way as headers, which is to say the `block_id` is appended as a url fragment (e.g. `www.blog.com/wikilink/#block_id`). With this url fragment, auto-scrolling to the corresponding html element id can be enabled. You will have to manually create those html elment ids yourself for now.

---

### File Paths 
⚠️ TODO: Unique filenames are still expected. This will change eventually.
```markdown
[[/directory/filename]]
```
File paths may be added to a link to point to a file with more specificity.

- Absolute paths should start with a forward slash `/`.
- ⚠️ TODO: Relative paths should start with a directory name.

File paths only work for inline wikilinks.

Resulting HTML (this will look identical to wikilinks without file paths):
```html
<a class="wiki-link" href="url">file's title</a>
```
### Labels (sometimes called 'aliases')
```markdown
[[filename|label text]]
```
When using labels, the text that appears after the `|` will be rendered in the `a` tag's inner text instead of the document's `title` frontmatter.

Labelling works for all wikilink levels (file, header, block).

Resulting HTML:
```html
<a class="wiki-link" href="url">label text</a>
```

### Embeds
```markdown
![[filename]]
```
By prepending `!` before a wikilink, the file's contents will be embedded in the current document rather than inserting just an `a` html tag.

Embeds only work for file-level wikilinks (not header or block).

Resulting HTML:
```html
<div class="wiki-link-embed">
  <div class="wiki-link-embed-title">
    // doc title here
  </div>
  <div class="wiki-link-embed-content">
    // embed content here
  </div>
  <a class="wiki-link-embed-link" href="url"></a>
</div>
```

### Embed Images
```markdown
![[image.png]]
```
Like the embeds above, link content will be rendered in the document body, but for images. Just be sure to add the file extension. Supported formats are `.png`, `.jpg`, `.gif`, `.psd`, `.svg`. Image wikilinks are not included in metadata.

Resulting HTML:
```html
<p>
  <span class="wiki-link-embed-image">
    <img class="wiki-link-img" src="img_relative_path"/>
  </span>
</p>
```

An svg's content will be inserted directly into the html, rather than being linked in an `img` tag. This is useful in case you want to programmatically alter the svg post-render:

Resulting HTML:
```html
<p>
  <span class="wiki-link-embed-image">
    <svg>
      // svg file content here
    </svg>
  </span>
</p>
```
---

### More Syntax

For more note-taking-related syntaxes such as \=\=highlights== and \~\~strikethroughs~~:

- For kramdown, check out their [project page](https://github.com/gettalong/kramdown/projects/1) ([highlights ticket](https://github.com/gettalong/kramdown/issues/559), [strikethrough ticket](https://github.com/gettalong/kramdown/issues/594)).
- For something that is functional now, see the [redcarpet markdown parser](https://github.com/vmg/redcarpet).


## MetaData
The following metadata are stored as frontmatter variables and are accessible in liquid templates:

- `attributed` (block backlinks)
- `attributes` (block forelinks)
- `backlinks`  (typed and untyped, file/header/block, back links)
- `forelinks`  (typed and untyped, file/header/block, 'forward' links)
- `missing`    (typed and untyped, file/header/block, forelinks that don't correspond to any document)

### Block Wikilink (Attribute) Metadata
The `attributes` and `attributed` frontmatter variables, which correspond to block wikilinks, are lists of objects with a `type` attribute for the wikilink type and a list of `urls` which are strings:
```yaml
-
  type: <str>
  urls: [<url_str>]
-
  ...
```
Example liquid:
```html
<!-- render as 👉 "link-type: title" -->

{% for attr in page.attributed %}
  {{ attr.type }}:
  {% for url in attr.urls %}
      {% assign linked_doc = site.documents | where: "url", attr.url | first %}
      <a class="wiki-link" href="{{ linked_doc.url }}">{{ linked_doc.title }}</a>
   {% endfor %}
{% endfor %}
```
### Inline Wikilink Metadata
The `forelinks` and `backlinks` frontmatter variables, which correspond to inline wikilinks, is a list of objects with a `type` attribute for the wikilink type and a `url` string. (Untyped wikilinks will have an empty attribute: `type: ""`):

```yaml
-
  type: <str>
  url: <url_str>
-
  ...
```
Example liquid:
```html
<!-- render as 👉 "link-type: title" -->

{% for backlink in page.backlinks %}
  {% assign linked_doc = site.documents | where: "url", backlink.url | first %}
  {{ backlink.type }}: <a class="wiki-link" href="{{ linked_doc.url }}">{{ linked_doc.title }}</a>
{% endfor %}
```
### Missing Metadata
`missing` is simply a list of filenames. filenames for both block level and inline level wikilinks are collected:
```yaml
- <filename_str>
- ...
```

## Liquid Filters

There are two types of liquid filters provided: One for jekyll document types and one for link (relationship) types.

Say you want to filter by jekyll document type. If you want to display 'post' backlinks and 'note' backlinks separately, just filter the backlinks metadata like so:

```html
<!-- show post backlink titles -->
{% assign post_backlinks = page.backlinks | doc_type: "posts" %}
{% for backlink in post_backlinks %}
  {% assign post = site.posts | where: "url", backlink | first %}
  {{ post.title }}
{% endfor %}

<!-- show note backlink titles -->
{% assign note_backlinks = page.backlinks | doc_type: "notes" %}
{% for backlink in note_backlinks %}
  {% assign note = site.notes | where: "url", backlink | first %}
  {{ note.title }}
{% endfor %}
```

Say you want to filter by link (relationship) types. If you have markdown like the following:

```markdown
author::[[gardener]]
```

Then you could filter by the `author` type like so:

```html
{% assign author_links = page.links | link_type: "author" %}
{% for link in author_links %}
  {% assign post = site.posts | where: "url", link.url | first %}
  {{ post.title }}
{% endfor %}
```

## Some Other Implementations...

### ...That Are Jekyll-Related
- [A pure liquid impl](https://github.com/jhvanderschee/brackettest)
- [A Jekyll Converter](https://github.com/metala/jekyll-wikilinks-plugin/blob/master/wikilinks.rb)
- [Another Jekyll Converter](https://github.com/doitian/wikilink-converter)
- [A template](https://github.com/maximevaillancourt/digital-garden-jekyll-template/blob/master/_plugins/bidirectional_links_generator.rb)

### ...That Are Wiki-Related
- [Gollum](https://github.com/gollum/gollum)
- [Wikicloth](https://github.com/nricciar/wikicloth)
