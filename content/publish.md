---
title: "Publishing your post"
description: "How to write, preview, and publish an Assignment 3 or Assignment 5 writeup on this blog."
---

Assignments 3 and 5 are submitted as a post on this site. A post is a Markdown file in this
site's repository, and you publish it by opening a pull request. Nothing is published until
that pull request is merged, so you can push work in progress without it appearing here.

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
hugo new content assignment3/<your-github-handle>.md
```

Use `assignment5/` in both commands for Assignment 5. The file name becomes the URL, so
`assignment3/jdoe.md` publishes at `/assignment3/jdoe/`. Use your GitHub handle: it is
unique, and it keeps the two posts you write this semester next to each other.

If your post has figures, make it a folder instead and put the images beside the Markdown:

```
content/assignment3/jdoe/
├── index.md
└── throughput.png        →  ![Throughput](throughput.png)
```

## 3. Fill in the front matter

Hugo creates the file with this block at the top. Everything between the `---` lines is
metadata, not prose:

```yaml
---
title: "Cutting agent cost by 60% without losing task success"
date: 2026-10-18
authors: ["Jane Doe"]
github: jdoe
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
| `github` | no | Your GitHub handle, linked from the byline. |
| `summary` | yes | One or two sentences, shown on the assignment page. Say what you found, not what you attempted. |
| `tags` | yes | Two to five topics. Check the [tag list](/tags/) and reuse existing ones where they fit. |
| `draft` | yes | `true` while you work. Set it to `false` in the pull request that submits the post. |
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

**Tables** are for your numbers. A before/after table with the workload held fixed is the
most useful thing most of these posts contain.

**Long output** — a full trace, a profile dump — goes in a collapsed block so it does not
bury the argument:

```markdown
{{</* collapse summary="Full profiler output" */>}}
...paste it here...
{{</* /collapse */>}}
```

**Figures** go beside `index.md` in your post folder and are referenced by file name.

## 5. Preview

```bash
hugo server -D
```

Open <http://localhost:1313>. `-D` includes drafts, which is how you see your own post
before it is published; it shows with an amber stripe so you can tell. The page reloads as
you save.

## 6. Open the pull request

```bash
git add content/assignment3/<your-github-handle>*
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

**Edit only your own post.** A pull request should touch your file and nothing else. If
something about the site itself is broken, open an issue instead.

**Fixes after the deadline are fine.** Typos, a broken figure, a clarification — open
another pull request. What is graded is the post as it stood at the deadline, so a late
rewrite of the substance will not help; a correction that makes your work clearer will.

The assignment specs themselves, the grading, and the late-day policy live on the
[course site](https://cs2680.com/assignments/index.html).
