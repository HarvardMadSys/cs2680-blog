---
title: "TODO: a real title, not \"Assignment 5\""
date: {{ now.Format "2006-01-02" }}
authors: ["TODO: Your Name"]
github: {{ .File.ContentBaseName }}
summary: "TODO: one or two sentences. What you found, not what you attempted."
tags: ["TODO"]
draft: true
---

TODO: open with the result. Which layer turned out to hold the time, and what did the
end-to-end numbers do once you fixed it?

<!--more-->

## The stack and the workload

The loop, the model, the serving configuration, the hardware, and the task set. Enough that
someone could rebuild your setup.

## The profile

Where the time, tokens, and compute actually go across the whole path. Show how you
measured, not only what you measured.

## Hypothesis

Written before you changed anything: what you expected to be the bottleneck, and what you
expected fixing it to buy. Keep it even if it turned out wrong — especially then.

## What I changed, layer by layer

Agent loop, model, serving system. For each: the change, and why the profile pointed at it.

## Results

Same workload, re-run. Which changes actually mattered, and by how much.

| Change | Layer | Throughput | p50 latency | p99 latency | Cost / task | Success rate |
| --- | --- | --- | --- | --- | --- | --- |
| Baseline | | | | | | |

## Where the hypothesis was wrong

What the numbers said that you did not expect, and what you think explains it.

## AI use

As the [course policy](https://cs2680.com/policy.html#ai-policy) requires: what you used and
what it did.
