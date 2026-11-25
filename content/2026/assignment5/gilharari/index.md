---
title: "Handpicking Optimizations to Balance Accuracy and Speed"
date: "2026-11-24"
authors: 
  - "Gil Harari"
summary: "Optimizations are most effective when used in tandem with one another. Implementations should be selective and
measured: limit reasoning and expensive models, balance time cap, and be aware of systems tradeoffs."
tags: [Agent-Design,Tool-Use,Context-Management]
draft: false
cover: "cover.webp"   # optional: a figure to show on the listing
---

Optimizations are most effective when used in tandem with one another. Implementations should be selective and
measured: limit reasoning and expensive models, balance time cap, and be aware of systems tradeoffs.

<!--more-->

## Selectively using thinking and expensive models

Expensive models and extensive reasoning for every model call is wasteful, causing simple tasks to prolong and slowing down 
the overall harness. In assignment 3, using the expert model for all retries, or as a planner/reviewer significantly
inflated the overall cost without a notable improvement in task solutions. In assignment 5, limiting the thinking only 
to the first three steps and after a failed tool call managed to retain number of tasks solved on Terminal-Bench while 
decreasing by almost 2 hours the overall time (together with a stricter cap per task).

## Slower system with more parallelism
In assignment 4, several attempts to speed up serving did not succeed in significant acceleration due to decreasing 
the KV cache hit rate. These included increasing the number of workers (over 10) and speculative decoding which led to
more conversation histories to store. This was partially accommodated with using the RAM as a second tier cache.

## Balancing the time cap
In assignments 3-5 including a timecap was necessary to prevent runaway tasks. However, using too strict of a rule
didn't provide an opportunity for my optimization attempts to come into fruition. For example, in assignment 4
my attempt for a rule to handle failed tasks (if less than 15 mins remaining then do an early hand in, otherwise reset 
the repo) often caused  the agent to hand in early because the initial attempt would take at least 20 min. Increasing 
the time cap unblocked this, and enabled my later versions to increase their solve count.

## Run-to-run noise
When submitting the same agent and engine specifications to the leaderboard, the number of solved tasks saw high 
variability in assignments 4 and 5. In assignment 4, the highest was 8/26 to 13/26 solved tasks(!) and in assignment 5
25/89 to 34/89. When so few solved tasks can make or break the success of the tested version, this can make it hard to 
attribute success/failure due to the  change in the agent and/or engine and not just the run-to-run noise.

## Importance of exact wording
In assignment 1, the (sub)agents were sensitive to the exact wording used in the prompt. For example, when asking one 
subagent to "survey" and the other to "read", the former explored the entire repo context while the latter focused only
on that specific file. 

## AI use

Claude was used to analyze code and run diffs in each assignment, and for the cover graphic. All the text is human-generated.  
