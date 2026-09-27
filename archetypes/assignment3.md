---
title: "TODO: a real title, not \"Assignment 3\""
date: {{ now.Format "2006-01-02" }}
authors: ["TODO: Your Name"]
github: {{ .File.ContentBaseName }}
summary: "TODO: one or two sentences. What you found."
tags: ["TODO"]
draft: true
---

TODO: open with the result. What did cost and latency do, and what stayed fixed while they
moved? Two sentences should be enough for a reader to decide whether to read the rest.

<!--more-->

## The workload

What task set you measured on, how many runs, and what counts as success. Numbers later in
the post mean nothing without this.

## Where the tokens and time went

Your baseline. Break the cost down until the breakdown suggests what to do.

## What I changed

One subsection per change: what you did, and the reasoning that made you expect it to work.

## Results

Same workload, same success criterion, before and after. A table beats a paragraph.

| Change | Cost / task | p50 latency | p99 latency | Success rate |
| --- | --- | --- | --- | --- |
| Baseline | | | | |

## What did not work

The changes that made things worse, or made no difference. Worth as much as the wins, and
nobody else can write them.

## What I could not reach

The bottlenecks that are still behind the black-box API. Assignment 5 is where you get to
open them.

## AI use

As the [course policy](https://cs2680.com/policy.html#ai-policy) requires: what you used and
what it did.
