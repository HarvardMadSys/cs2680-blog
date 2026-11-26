---
title: "Handpicking Optimizations to Balance Accuracy and Speed"
date: "2026-11-24"
authors: 
  - "Gil Harari"
summary: "Optimizations are most effective when used in tandem with one another. Implementations should be selective and
measured: limit reasoning and expensive models, balance time cap, and be aware of systems tradeoffs."
tags: [agent-design,tool-use,context-management]
draft: false
cover: "cover.webp"
---

Optimizations are most effective when used in tandem with one another. Implementations should be selective and
measured: limit reasoning and expensive models, balance time cap, and be aware of systems tradeoffs.

<!--more-->

## Selectively using thinking and expensive models

Using expensive models and extensive reasoning for every model call is wasteful in time and tokens, causing simple tasks
to prolong and slowing down the overall harness. In assignment 3, using the expert model for all retries, or as a 
planner/reviewer significantly inflated the overall cost without a notable improvement in task solutions. Indeed, in a 
run where the expert was used for every retry, as a reviewer (requirements checker), tester (subagent to write its own 
tests), and planner (explore repo and plan), the number of expert calls was 116, the expert/total cost was 
7.13/8.32 USD, and the number of locally solved tasks was 3/5. With the expert only used for rescue, the 
number of expert calls was 4, the expert/total cost was 0.28/1.27 USD, and the number of locally solved tasks
was 4/5. In assignment 5, limiting the thinking only to the first step and after a failed tool call managed to retain
number of local tasks solved on Terminal-Bench (8/16) while decreasing the overall number of output tokens (from about
38k tokens per task to 33k, ~13% decrease). Interestingly, the number of output tokens per call dropped by half (from
about 1.4k tokens to 0.7k) but the number of model calls increased (428 to 727) leading to the overall smaller decrease
in output tokens. Wall clock time per task on average remained flat (311 to 309 seconds). While as expected the time per
call fell from (11.6 to 6.8 seconds), this was offset by the increase in number of overall calls.


## Slower system with more parallelism
In assignment 4, several naive attempts to speed up serving did not initially succeed in significant acceleration due to
decreasing the KV cache hit rate. First, increasing the number of concurrent workers from 5 to 13 caused the hit rate to
fall from 88% to 52%. The total run time still decreased (from 135 min to 128 min), yet not as much as expected by
increasing the number of workers over 2.5x. Secondly, using speculative decoding leads to less free GPU memory for the 
KV cache as more memory is occupied for the draft model and verification buffers. In my initial MTP attempt, the GPU 
space for KV cache decreased from 305k to 116k tokens and the maximum number of running requests decreased from 16 to 3.
Throughput increased from 165 to 258 tokens/s when processing one request at a time. However, with eight concurrent 
requests, throughput instead decreased from 572 to 367 tokens/s. This was partially accommodated by using the RAM as a 
second tier cache, increasing the hit rate from 11% to 35%. Turning off prefill CUDA graphs, increasing the static 
memory pool, and a leaner Mamba cache managed to increase it to 95%. With these fixes, the submitted MTP version reduced 
the time per turn from 24 to 18 seconds.

## Balancing the time cap
In assignments 3-5 including a timecap was necessary to prevent runaway tasks. However, using too strict of a rule
didn't provide an opportunity for my optimization attempts to come into fruition. For example, in assignment 4
my attempt for a rule to handle failed tasks (if less than 15 mins remaining then do an early hand in, otherwise reset 
the repo) often caused  the agent to hand in early because the initial attempt would take at least 20 min. Increasing 
the time cap from 35 to 60 minutes unblocked this, and enabled my later versions to increase their solve count.

## Run-to-run noise
When submitting the same agent and engine specifications to the leaderboard, the number of solved tasks saw high 
variability in assignments 4 and 5. In assignment 4, six different versions were submitted twice with an average gap
of 2.8 tasks (between the two submissions), the widest of which was 8/26 to 13/26(!). In assignment 5, the widest gap
was 25/89 to 34/89. When so few solved tasks can make or break the success of the tested version, this can make it hard
to attribute success/failure due to the  change in the agent and/or engine and not just the run-to-run noise.

## Importance of exact wording
In assignment 1, the (sub)agents were sensitive to the exact wording used in the prompt. For example, when asking one 
subagent to "survey" and the other to "read", the former explored the entire repo context while the latter focused only
on that specific file. 

## AI use

Claude was used to analyze code and run diffs in each assignment, and for the cover graphic. All the text is human-generated.  
