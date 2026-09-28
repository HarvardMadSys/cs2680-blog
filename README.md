# blog.cs2680.com

The CS2680 student blog, built with [Hugo](https://gohugo.io/). Assignments 3 and 5 are
submitted as posts here.

**Writing a post? Read the [publishing guide](content/publish.md)** — it is also on the site
at `/publish/`. The rest of this file is about the site itself.

## Run locally

Hugo **extended**, v0.164.0 or newer:

```bash
brew install hugo          # macOS
hugo server -D             # -D shows drafts
```

Then open <http://localhost:1313>.

## Layout

| Path | What it is |
| --- | --- |
| `hugo.toml` | Configuration: menu, taxonomies, params |
| `content/2026/` | One offering. `_index.md` is its landing page |
| `content/2026/assignment1/`, `.../assignment3/`, `.../assignment5/` | The posts, one folder per student |
| `content/publish.md` | The publishing guide students follow |
| `archetypes/` | Front matter and outline `hugo new content` starts a post from |
| `layouts/` | All templates. There is no theme directory |
| `assets/css/` | The stylesheets |
| `static/` | Copied verbatim to the site root (`_redirects`, `seas-logo.png` for the footer, the icons) |
| `assets/madsys-logo.svg` | The lab logo the site mark is taken from |
| `build.sh` | The Cloudflare Pages build command |

### Templates

`layouts/` uses Hugo's current template structure (`_partials/`, `_shortcodes/`, `_markup/`):

- `baseof.html` wraps every page in the course site's header and footer
- `home.html` is the front page: the current offering's assignment tiles, the latest posts
  across every offering, then the earlier offerings
- `list.html` is both an offering page (tiles, then every post of that year) and an
  assignment page (the whole roster of posts, with a filter box)
- `single.html` is one post -- byline, assignment badge, prose, tags, prev/next -- and also
  a standalone page such as the publishing guide, which gets a contents list from `toc: true`
- `_partials/site-header.html` is the brand and the four-item menu; the mark is inline SVG
- `_partials/assignment-tiles.html`, `_partials/offerings.html` and
  `_partials/browse-links.html` are what the home page and the offering page share
- `taxonomy.html` / `term.html` are the author and tag indexes
- `_markup/render-table.html` gives Markdown tables the course site's table styling
- `_markup/render-image.html` turns an image with a title into a captioned figure
- `_markup/render-heading.html` gives every heading a link to itself
- `_partials/pager.html` is the page row under a list; `pagerSize` is in `hugo.toml`
- `robots.txt` is a template, not a static file: it disallows everything outside production

## The look

The blog borrows the course site's design rather than a Hugo theme, so the two read as one
family: same palette, same type, same white bar with a 3px crimson rule, same footer band.
What makes it a different site is the header. The course site's header is the SEAS lockup;
this one is the blog's own mark and name, with the course code and term underneath. The
SEAS lockup moved to the footer, where the rest of the institutional apparatus already was.

`courseCode` and `courseName` are separate params because the two places the course is
named want different amounts of it: the header brand takes the code, which is all that
fits under a wordmark on a phone, and the home page takes the name, since the code is
already in the site title above it.

The navigation bar is three items — Home, the current offering, and the course site. The
assignments are one click away on the front page and on `/2026/`; the publishing guide has
its own section on the front page; the author and tag indexes are reached from a byline or
from the list pages. The footer lists every page the bar leaves out, so nothing here is
reachable only from the navigation.

Nothing on the public pages says that a post is required, what it is worth, or when it is
due. That is the course site's business. This one is a blog.

`static/favicon.svg` is a byte-for-byte copy of <https://cs2680.com/favicon.svg>: the
MadSys hexagon with the square wave inside it, on a white rounded plate. The two sites
show the same icon on purpose. If the course site's favicon ever changes, copy it across
rather than redrawing it — this file has no edits of its own, and it should stay that way.

The header mark is the same two paths, without the white plate, which the white header bar
already provides. Between them these are the only copies of the mark in the repo;
`assets/madsys-logo.svg` is the full lab logo and carries the mark as an embedded 2048px
bitmap, so it is kept for provenance rather than used directly.

`static/favicon.png` (32px) is the fallback for browsers without SVG favicon support and
`static/apple-touch-icon.png` (180px, white square) is what iOS puts on a home screen. Both
are rendered from `favicon.svg` at 512px and downsampled; regenerate them if it changes.

- **`assets/css/course.css`** is a verbatim copy of <https://cs2680.com/css/main.css>,
  fetched 2026-09-19. It owns the palette, the type stack, the header, the footer, tables
  and prose. **Do not hand-edit it.** To pick up changes from the course site:

  ```bash
  curl -sL https://cs2680.com/css/main.css -o assets/css/course.css
  # then put the header comment back at the top of the file
  ```

  It is vendored rather than linked across origins so that the site builds and previews
  offline, and so a change to the course site cannot restyle the blog mid-semester.
- **`assets/css/blog.css`** holds what only the blog needs: assignment tiles, post cards,
  the filter, the byline, tag pills, the author index. Every colour in it is a token from
  `course.css`. Blog-only styling goes here.
- **`assets/css/syntax.css`** is generated, not written:
  `hugo gen chromastyles --style=github > assets/css/syntax.css`.

Bootstrap 5.3.3 and the Lato / Open Sans webfonts load from the same CDNs and at the same
pinned versions as the course site, because `course.css` builds on them.

The header and footer markup mirrors `https://cs2680.com/header.html`. The navigation
itself comes from `[[menu.main]]` in `hugo.toml`, so adding a link does not mean touching a
template.

## Notes

- **Future-dated posts are published.** `buildFuture = true` is set deliberately: Hugo
  hides future-dated content by default, which would silently drop a submission whose date
  was mistyped.
- **Drafts are not published.** A post with `draft: true` appears only under
  `hugo server -D`, with an amber stripe.
- **Posts are filed by year.** `content/2026/assignment3/jdoe.md` publishes at
  `/2026/assignment3/jdoe/`. Nothing published in one year moves when the next year's
  posts arrive.
- **Adding an assignment** means adding a section under the year with an `assignment`
  param in its `_index.md`, plus an archetype named after it. The home page and the
  offering page pick it up from there; nothing lists the sections by name, and the tile row
  reflows for however many there are.
- **Lists paginate at 20, the filter does not.** A list page shows twenty posts and a page
  row; the filter box searches the whole collection, because `_partials/post-filter.html`
  also emits every card into a JSON island and swaps the matches in. At eighty posts that
  island is ~7 KB gzipped. A filter that searched only the page in front of you would tell
  a student their classmate's post does not exist.
- **`hugo new content` needs `--kind`.** The archetype is chosen from the first path
  segment, which is now the year, so the command in the publishing guide passes
  `--kind assignment3` explicitly.

## Rolling the site over to a new year

1. `mkdir content/2027` and copy `content/2026/_index.md` into it, with `year: 2027`,
   `term: "Fall 2027"` and `weight: 2027`.
2. Copy the `assignment*/_index.md` files across.
3. In `hugo.toml`, set `currentYear = "2027"`, `term = "Fall 2027"`, and point the `year`
   menu URL at `/2027/`.

`content/2026/` stays where it is. Its URLs do not change, and the home page lists it
under **Earlier offerings**.

## Deploying (Cloudflare Pages)

Connect the repository as a Pages project and set:

| Setting | Value |
| --- | --- |
| Build command | `./build.sh` |
| Build output directory | `public` |
| Environment variable | `HUGO_VERSION` = `0.164.0` |

**`HUGO_VERSION` is not optional.** Cloudflare's build image installs Hugo **0.54.0** when
it is unset, which predates the `layouts/_partials` template structure this site uses, so
the build produces pages with no layout rather than an error. `build.sh` checks the version
first and fails with that sentence in the log, so if someone forgets, the log says what to
do instead of what went wrong.

The custom domain is configured in the Pages dashboard, under the project's **Custom
domains** tab. There is no file in this repository that sets it — the old `static/CNAME`
was a GitHub Pages mechanism and has been removed, because leaving it there invites someone
to edit it and expect an effect.

### What `build.sh` does

Two things the dashboard's build-command box cannot express legibly:

- **Checks the Hugo version**, as above.
- **Gives previews their own `baseURL`.** `hugo.toml` pins `https://blog.cs2680.com/`, and
  `_partials/head.html` emits absolute URLs for `og:url`, `rel=canonical` and the RSS feed.
  A preview built with the production baseURL tells a crawler that `blog.cs2680.com` is
  what it just read. For any branch other than `main`, the script passes Cloudflare's
  per-deployment `CF_PAGES_URL` instead, plus `-e preview`.

`-e preview` is what three other things read:

| | production | preview |
| --- | --- | --- |
| `layouts/robots.txt` | `Disallow:` + sitemap | `Disallow: /` |
| CSS in `_partials/head.html` | minified, fingerprinted | plain `site.css` |
| Google Analytics | emitted if configured | never |

Run `./build.sh` with no Cloudflare variables set and it builds for production, which is
what you want when checking a release locally.

### Redirects

`static/_redirects` is copied to the root of the build output, where Pages consumes it
without serving it. It currently keeps the pre-2026 paths (`/assignment3/…`) working.

### Two things to watch

- **Pull requests from forks get no preview.** Pages only builds branches that live in this
  repository. The publishing guide tells students to push a branch here, which works; if
  they fork instead, a TF gets nothing to click and you would need a GitHub Action to build
  the PR.
- **Build quota.** The free plan is 500 builds a month, one at a time. Eighty students
  pushing branches in deadline week can reach that. Pages' **preview branch control**
  settings can narrow which branches trigger a build.

### Third-party requests

Bootstrap, KaTeX and Mermaid load from jsDelivr and the webfonts from Google Fonts, all
version-pinned with SRI where applicable. Cloudflare does not proxy them. If the site ever
goes through a privacy or CSP review, those four are what have to be vendored.
