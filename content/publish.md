---
title: "Publishing your post"
description: "How to write, preview, and publish a post on this blog."
kicker: "Guide"
toc: true
---

A post is a Markdown file in this repository — or a folder holding the Markdown and its
figures, which is what most posts end up being. You publish one by opening a pull request.
Nothing appears here until that pull request is merged, so pushing work in progress is
safe.

## 1. Get the site

```bash
git clone git@github.com:HarvardMadSys/cs2680-blog.git
cd cs2680-blog
```

You need [Hugo](https://gohugo.io/) **extended**, v0.164.0 or newer, to preview your post:

```bash
brew install hugo          # macOS
sudo snap install hugo     # Linux
hugo version               # should print "extended"
```

## 2. Start your post

Work on a branch named after you and the assignment, and let Hugo create the file:

```bash
git checkout -b assignment3/<your-github-handle>
hugo new content --kind assignment3 2026/assignment3/<your-github-handle>/index.md
```

Put `assignment1` or `assignment5` in place of `assignment3` everywhere for those. An
Assignment 1 post is a showcase of your web UI rather than a measurement writeup, so its
outline is different and it carries a link to a public repository; the archetype has the
shape.

That gives you a folder, which is what you want as soon as you have a figure — the images
sit beside the Markdown and are referenced by file name:

```
content/2026/assignment3/jdoe/
├── index.md
└── throughput.png        →  ![Throughput](throughput.png)
```

Posts are filed under the year, so this year's go in `2026/`. The path becomes the URL, so
that folder publishes at `/2026/assignment3/jdoe/`. Use your GitHub handle for the folder
name; it keeps your posts next to each other.

If you are certain your post will have no figures, a bare `<your-github-handle>.md` in the
assignment folder works the same way.

## 3. Fill in the front matter

Hugo creates the file with this block at the top. Everything between the `---` lines is
metadata, not prose:

```yaml
---
title: "Cutting agent cost by 60% without losing task success"
date: 2026-10-18
authors: ["Jane Doe"]
summary: "Where the tokens went, the four changes that mattered, and the one that made things worse."
tags: ["prompt-compression", "model-routing", "caching"]
draft: true
---
```

| Field | Required | What it does |
| --- | --- | --- |
| `title` | yes | The post title. Write a real one; it is what people scan on the assignment page. |
| `date` | yes | Publication date, `YYYY-MM-DD`. Sorts the assignment page. |
| `authors` | yes | Your name, as a list. It becomes your [author page](/authors/). Spell it the same way in both posts. |
| `summary` | yes | One or two sentences, shown on the assignment page. Say what you found. |
| `tags` | yes | Two to five topics. Check the [tag list](/tags/) and reuse existing ones where they fit. |
| `draft` | yes | `true` while you work. Set it to `false` in the pull request that submits the post. |
| `toc` | no | `true` adds a contents list at the top. Worth it past five or six sections. |
| `math` | no | `false` turns KaTeX off for the page. It is on by default. |
| `mermaid` | no | `true` enables Mermaid diagrams in ` ```mermaid ` fences. |

## 4. Write it

Standard Markdown. A few things this site sets up for you:

**Code** is highlighted; name the language on the fence.

````markdown
```python
def budget(messages: list[Message]) -> int:
    return sum(len(m.content) for m in messages) // 4
```
````

**Math** renders with KaTeX, inline as `$p_{99}$` and display as `$$ ... $$`.

**Tables** are for your numbers. A before/after table with the workload held fixed does
more work than a paragraph about it.

**Long output** — a full trace, a profile dump — goes in a collapsed block so it does not
bury the argument:

```markdown
{{</* collapse summary="Full profiler output" */>}}
...paste it here...
{{</* /collapse */>}}
```

**Figures** go beside `index.md` in your post folder and are referenced by file name. Give
every one of them alt text and a caption; a Markdown image with a title renders as a
captioned figure.

## 5. Preview

```bash
hugo server -D
```

Open <http://localhost:1313>. `-D` includes drafts, so you can see your own post before it
is published; it shows with an amber stripe. The page reloads as you save.

## 6. Open the pull request

```bash
git add content/2026/assignment3/<your-github-handle>
git commit -m "Assignment 3: <your title>"
git push -u origin assignment3/<your-github-handle>
```

Then open a pull request against `main`. Before you do, check that:

- `draft` is `false`
- `summary`, `authors`, `date` and `tags` are filled in
- `hugo server` shows no error, and your post looks right
- your post contains only your own work, and discloses AI use as the
  [course policy](https://cs2680.com/policy.html#ai-policy) requires

A TF reviews the pull request. Once it is merged, your post is live here within a few
minutes.

## Rules of the road

**Your post is public.** It is on the open internet under your name. Do not paste API keys,
private endpoints, or anything from a private course repository that is not yours to
publish.

**Edit only your own post.** A pull request should touch your own post and nothing else. If
something about the site itself is broken, open an issue instead.

**Fixes after the deadline are fine.** Typos, a broken figure, a clarification — open
another pull request. What is graded is the post as it stood at the deadline, so rewriting
the substance late will not change the grade.

The assignment specs, the grading, and the late-day policy live on the
[course site](https://cs2680.com/assignments/index.html).
