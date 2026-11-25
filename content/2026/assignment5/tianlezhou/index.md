---
title: How to decide whether a change actually helped my coding agent?
date: 2026-11-25
authors: ["Tianle Zhou"]
summary: This blog discusses my decisions when designing the agents in Assignments 2-5.
tags: ["Agent", "Harness Design"]   # 2-5 tags; reuse existing ones from the blog's tag list
draft: false
toc: true        # more than five sections
# cover: "a5_leaderboard_runs.svg"   # optional; it gets cropped to 16:9 on the listing page
---



Consider a scenario where you have a single GPU and a 20-minute time limit. You need to decide whether to turn on multi-token prediction (MTP) in your coding agent. Your profiling tells you that with 10 parallel requests, the throughput would go from 147 to 249 tokens/s. Would you choose to turn on MTP?

I tried to answer many questions like this while designing the harness. Here I summarize some scenarios that I encountered.



## A2: What the agent needed when it called "done"

The done-gate problem was the most significant problem I solved in Assignment 2, and it was pretty tricky.

- When the agent called done, there were sometimes still tiny problems in the diff patch it generated that it was not aware of.
  - I added a short prompt asking it to check the format before calling the "done" tool, but it didn't help.
  - However, it could be fixed by simply giving it the diff patch directly and asking it to do it again when it called "done".
- The design of the harness should be direct. Agents are sometimes static and dumb.

Evidence: adding this design raised the pass rate from 0/3 to 3/3.

## A3: Cache management

People sometimes think that compressing the context window is always good. I made the same mistake. SGLang and vLLM use a prefix cache that reuses the KV cache from previous requests to avoid redundant prefilling. Yet when you compress the context or evict some of the tool-call results in later runs just to save tokens, you may end up spending more time on prefilling. This is because the prefix cache does not hit when the "prefix" is modified.

Evidence: the cost per trial dropped from $0.031 to $0.027 (−12%).

## A4: Engine-harness co-design

Sometimes you need to think about the engine and the harness together.

- Think about this scenario: the first request from agent A finishes. To save time, you open agent B and submit another request.
  - Agent B's request gets into the engine and kicks out the cache of request A.
  - In the end, when agent A submits another request, the system has to compute all the tokens again.

Of course, we don't want to do that. Therefore, we need to co-design the engine along with the harness. The harness should know when to submit which request to get the least redundant computation.

Evidence: the end-to-end running time for the tasks dropped from 1253 s to 365 s.

## A5: Always benchmark

Back to the problem that I raised at the beginning of the post. While the large throughput looks super attractive in profiling, you never know what it costs until you really put the configuration into the agent scenario. Enabling MTP reduced the KV capacity from 135K tokens to 70-86K.

In such cases, you always want to run it on an end-to-end benchmark. In my experiment, the number of passed tasks dropped from 28/89 to 21/89 on Terminal-Bench 2.0.

## AI use

I used Claude Code to support my project and to prepare the materials for this blog.
