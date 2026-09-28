---
title: "Publishing your post"
description: "How to write, preview, and publish a post on this blog."
kicker: "Guide"
---

Each post lives in its own folder with a Markdown file (`index.md`) and any images.
Posts are published by opening a pull request.

## 1. Preparation

First, clone the repo:

```bash
git clone git@github.com:HarvardMadSys/cs2680-blog.git
cd cs2680-blog
```

You need [Hugo](https://gohugo.io/), v0.164.0 or newer, to preview your post: (for other operating systems, please see [Hugo installation guide](https://gohugo.io/installation/).)

```bash
brew install hugo          # macOS
sudo snap install hugo     # Linux
hugo version               # should print "extended"
```

## 2. Start writing your post

Work on a branch named after you and the assignment, and let Hugo create the file: (Put `assignment1` or `assignment5` in place of `assignment3` everywhere for those.)

```bash
git checkout -b assignment3/<your-name>
hugo new content --kind assignment3 2026/assignment3/<your-name>/index.md
```

That gives you a new folder, where you can put the post file and the supplementary files:

```
content/2026/assignment3/junchengyang/
├── index.md
└── throughput.png        →  ![Throughput](throughput.png)
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
| `toc` | no | `true` adds a contents list at the top. Worth it if it has more than five sections. |
| `mermaid` | no | `true` enables Mermaid diagrams in ` ```mermaid ` blocks. |

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


{{<collapse summary="Full profiler output">}}
...paste it here...
{{</collapse>}}

  ```markdown
  {{</*collapse summary="Full profiler output"*/>}}
  ...paste it here...
  {{</*/collapse*/>}}
  ```

- **Figures:** Place these beside `index.md` in your post folder and reference them by file name. Give
  every one of them alt text and a caption.

## 5. Preview

To preview, please execute the following command in the terminal at the root directory of this repo.

```bash
hugo server -D
```
`-D` includes drafts, so you can see your own post before it is published.
If there is no errors displayed, open <http://localhost:1313> to preview.
Pages will be reloaded as you save.

## 6. Open the pull request

```bash
git add content/2026/assignment3/<your-name>
git commit -m "Assignment 3: <your title>"
git push -u origin assignment3/<your-name>
```

Then open a pull request against `main`. Before you do, check that:

- `draft` is `false`;
- `summary`, `authors`, `date` and `tags` are filled in;
- `hugo server` shows no error, and your post looks right;
- your post contains only your own work, and discloses AI use as the
  [course policy](https://cs2680.com/policy.html#ai-policy) requires.

A TF will review the pull request. Once it is merged, your post will be live here.

## Notes

**Your post is public.** Do not leak API keys, private endpoints, or anything private.

**Only edit your own post.** A pull request should only touch your own post and nothing else.

**Fixes after the deadline are fine.**  Feel free to open another pull request if you have typos, a broken figure, or want to add further clarification.
However, grading is based on the state of your post at the deadline, so any
subsequent rewrites will not affect your score.

The assignment specs, the grading, and the late-day policy are on the
[course site](https://cs2680.com/assignments/index.html).
