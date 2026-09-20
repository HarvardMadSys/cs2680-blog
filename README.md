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
| `content/assignment3/`, `content/assignment5/` | The posts, one file per student |
| `content/publish.md` | The publishing guide students follow |
| `archetypes/` | Front matter and outline `hugo new content` starts a post from |
| `layouts/` | All templates. There is no theme directory |
| `assets/css/` | The stylesheets |
| `static/` | Copied verbatim to the site root (`CNAME`, logo, favicon) |

### Templates

`layouts/` uses Hugo's current template structure (`_partials/`, `_shortcodes/`, `_markup/`):

- `baseof.html` wraps every page in the course site's header and footer
- `home.html` is the front page: assignment tiles, then the latest posts
- `list.html` is an assignment page: the whole roster of posts, with a filter box
- `single.html` is one post: byline, assignment badge, prose, tags, prev/next
- `taxonomy.html` / `term.html` are the author and tag indexes
- `_markup/render-table.html` gives Markdown tables the course site's table styling
- `_markup/render-image.html` turns an image with a title into a captioned figure

## The look

The blog is meant to read as part of <https://cs2680.com/>, so it borrows that site's
design rather than a Hugo theme.

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
- **`mainSections`** in `hugo.toml` lists which sections count as posts. Adding a third
  assignment means adding its section there and giving its `_index.md` an `assignment`
  param.

## Deploying

`static/CNAME` points the built site at `blog.cs2680.com`. There is no CI workflow yet —
add one that runs `hugo --gc --minify` and publishes `public/`.
