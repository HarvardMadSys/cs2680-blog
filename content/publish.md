---
title: "Publishing your post"
description: "A step-by-step guide to writing, previewing, and publishing your post on the course blog."
kicker: "Guide"
---

## 1. Preparation

Open <https://github.com/HarvardMadSys/cs2680-blog> and press **Fork**. Then clone the fork
you just made and point `upstream` at the original, so you can pull in other people's posts
later:

```bash
git clone git@github.com:<your-github-username>/cs2680-blog.git
cd cs2680-blog
git remote add upstream git@github.com:HarvardMadSys/cs2680-blog.git
```

`origin` is now your fork, which you can push to; `upstream` is the course repository, which
you cannot.

You need [Hugo](https://gohugo.io/), v0.164.0 or newer, to preview your post: (for other operating systems, please see [Hugo installation guide](https://gohugo.io/installation/).)

```bash
brew install hugo          # macOS
sudo snap install hugo     # Linux
hugo version               # should print "extended"
```

## 2. Start writing your post

Start from an up-to-date `main`, then branch. (Put `assignment1` or `assignment5` in place of
`assignment3` everywhere for those.)

```bash
git fetch upstream
git checkout -b assignment3/<your-name> upstream/main
hugo new content --kind assignment3 2026/assignment3/<your-name>/index.md
```

That gives you a new folder, where you can put the post file and the supplementary files:

```
content/2026/assignment3/junchengyang/
├── index.md
└── throughput.svg        →  ![Throughput](throughput.svg)
```

If your post doesn't have figures, a single `<your-name>.md` in the
assignment folder works the same way.

## 3. Edit the metadata block

Hugo creates the file with a metadata block at the top. Everything between the `---` lines is
metadata:

```yaml
---
title: "Cutting agent cost by 60% without losing task success rate"
date: 2026-09-28
authors: ["Juncheng Yang"]
summary: "With a good management in context, the agent is able to avoid a lot of costs, while also preserving the task success rate."
tags: ["prompt-compression", "caching"]
draft: true
---
```

| Field | Required | What it does |
| --- | --- | --- |
| `title` | yes | The post title. |
| `date` | yes | Publication date, `YYYY-MM-DD`. Sorts the assignment page. |
| `authors` | yes | Your name (as a list). It will be used for the [author page](/authors/). Keep it consistent across your posts. |
| `summary` | yes | One or two sentences about what you found. I will be shown on the assignment page. |
| `tags` | yes | Two to five topics. Check the [tag list](/tags/) and reuse existing ones where they fit. |
| `draft` | yes | `true` while you are still working on it. Set it to `false` before you create the pull request. |
| `cover` | no | A file in your post folder, e.g. `"cover.webp"`. Shown at the top of your post, as the thumbnail on the assignment page, and as the preview when someone shares the link. |
| `coverAlt` | no | Alt text for the cover, for screen readers. |
| `coverCaption` | no | A caption under the cover on the post page. |
| `toc` | no | `true` adds a contents list at the top. Worth it if it has more than five sections. |
| `mermaid` | no | `true` enables Mermaid diagrams in ` ```mermaid ` blocks. |

**About `cover`.** It is optional, but a post with one stands out on a page of eighty. For
an Assignment 1 showcase it should be a screenshot of your interface — that is the fastest
way to tell a reader what your app looks like before they click.

Hand it a full-size screenshot; it is resized for you. It appears in two places and is
treated differently in each: whole at the top of your post, and cropped to 16:9 for the
thumbnail on the assignment page. Anything roughly landscape survives that crop; a tall
portrait screenshot will lose its top and bottom, so if you have one, put it in the body of
your post instead and leave `cover` out.

Because the cover already appears at the top of your post, do not also embed it in the
first paragraph — it would show twice.

## 4. Write the post

Just use the standard Markdown format. On top of that, we also have some enhanced features:

- **Code highlighting.** 

  ````markdown
  ```python
  def budget(messages: list[Message]) -> int:
      return sum(len(m.content) for m in messages) // 4
  ```
  ````
- **Math.** Inline as `$p_{99}$` and display as `$$ ... $$` (Rendered with KaTeX).
- **Long output:** A full trace or a profile dump goes in a collapsed block so it does not
  bury the argument:

  ```markdown
  {{</*collapse summary="Full profiler output"*/>}}
  ...paste it here...
  {{</*/collapse*/>}}
  ```
- **Figures:** Place these beside `index.md` in your post folder and reference them by file
  name. Give every one of them alt text and a caption.

## 5. Figures and file sizes

For figures, it is recommended to place them in the same directory as the markdown file. Svg (for diagrams) and webp (for photos) are preferred formats

Use **SVG for anything drawn** (plots, diagrams, architecture sketches) to stay sharp at
any zoom.

Use **WebP for anything photographed or captured** (screenshots, photos). You can easily convert your files via the command line:

```bash
cwebp -q 80 screenshot.png -o cover.webp      # brew install webp
magick screenshot.png -quality 80 cover.webp  # or ImageMagick
```

Keep your entire post folder **under 10 MB**. Please keep in mind:

- **Compress screenshots** before committing.
- **No video files.** Upload videos to YouTube, Drive, or Panopto, and link to them.
- **No datasets, model weights, logs, or `node_modules`.**

## 6. Preview

To preview, please execute the following command in the terminal at the root directory of this repo.

```bash
hugo server -D
```
`-D` includes drafts, so you can see your own post before it is published.
If there is no errors displayed, open <http://localhost:1313> to preview.
Pages will be reloaded as you save.

## 7. Open the pull request

Push the branch to your own fork:

```bash
git add content/2026/assignment3/<your-name>
git commit -m "Assignment3(<your name>): <your title>"
git push -u origin assignment3/<your-name>
```

GitHub will display a link to open your pull request.
Ensure your pull request is targeting the **`main` branch of `HarvardMadSys/cs2680-blog`**,
and that it only contains changes to your own post folder. Before submitting, verify that:

- `draft` is `false`;
- `summary`, `authors`, `date` and `tags` are filled in;
- your figures are SVG or WebP, and the post folder is under about 2 MB;
- `hugo server` shows no error, and your post looks right;
- your post contains only your own work, and discloses AI use as the
  [course policy](https://cs2680.com/policy.html#ai-policy) requires.

A TF will review the pull request. Once it is merged, your post will be live here.

If the review takes a while and other posts land first, update your branch rather than
opening a new pull request:

```bash
git fetch upstream
git rebase upstream/main
git push --force-with-lease
```

## Notes

**Your post is public.** Do not leak API keys, private endpoints, or anything private.

**Only edit your own post.** A pull request should only touch your own post and nothing else.

**Fixes after the deadline are fine.**  Feel free to open another pull request if you have typos, a broken figure, or want to add further clarification.
However, grading is based on the state of your post at the deadline, so any
subsequent rewrites will not affect your score.

The assignment specs, the grading, and the late-day policy are on the
[course site](https://cs2680.com/assignments/index.html).
