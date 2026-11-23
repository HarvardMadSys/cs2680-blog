---
title: "Counterfactuals about Serving a LLM Agent"
date: 2026-11-24
authors: ["Xiangcheng Zhang"]
summary: "Optimal agent serving and design strategies depends on the specific patterns of the model being served"
tags: ["inference-scaling", "context-cache", "server-scheduling"]
draft: false
# cover: "cover.webp"   # optional: a figure to show on the listing
---

During developing the agents in Assignment 2-5, I found that the first natural decision may lead to sub-optimal designs, and the optimal design
for the LLM may indeed challeng long standing principles

<!--more-->

## Inference-scaling: naive parallel versus reasoning scaling

To scale iuference compute for better performance, the recent progress of reasoning models and agentic models have pointed to sclaing iup
the reasoning token length and also scale up environment interaction, compared with naive best-of-N sampling introduced in early 2024.
Hoever, when serving a weak model as the ones used in Assignment 4 and 5, we found out that have the model reason over its failures and iteratively refine is wasting time and tokens, since it lacks sufficient reasoning capabilities and may just stuck in the failure pattern. In that case, naively use parallel best-of-N scaling may have better performance. Here is the evidence.

**Assignment 4:**
- When a patch failed and the agent was asked to repair it, 27 of 37 repairs
  came back with **the same result** (73 %); 3 were solved (8 %). First
  attempts were solved 55 % of the time (41 of 75).
- Two graded submissions differing in one thing:
  - submission 12: six attempts per task, each appended to the same
    conversation: **11/26** in 3 h 32, 11,235 turns;
  - submission 13: each attempt in a fresh conversation: **15/26** in 3 h 33,
    9,275 turns. Turns per solve 1,021 → 618.
  One run each, so this is within run-to-run noise (z = 1.1, p = 0.27).


**Assignment 3:**
- A repair of a near miss (1 of 2 hidden tests failing) by the expensive
  model came back 1 of 2 failing again, for $0.41. Repair was switched off.


## The system perf bottleneck may depend on unexpected factors

When working on Assignment 4, we found that the throughput monotonically increased while we increase the concurrency of number of conversations in parallel, but dropped significantly when scaled up to 26, with a low cache hit rate. We first suspected that the reason may be cache full. But we then benchmarked the performance versus prompt length, and found it that barely varied between long and short prompt. We then found the problem: the LLM is a hybrid structure with Mamba layers and the engine has a fixed number os slots for mamba states cache. When the number of conversations threads went over 21, the slots are full and mamba states are evicted, so there is a full context refill everytime. We thus limited the maximum concurrency in our harness.

**Assignment 4**
- Own benchmark of agent-like conversations (6 turns each):

  | conversations at once | time | output tokens/s | cache hit rate | wait for the first token, 95th percentile |
  |---|---|---|---|---|
  | 16 | 64.3 s | 757 | 0.81 | 1.99 s |
  | 26 | 148.6 s | 537 | 0.26 | 22.66 s |

**Assignment 5**
- 24 open (budget1) vs 16 open (live16), same agent: model time per turn
  27.6 s → 20.7 s, hit rate 0.68 → 0.84, share of opened tasks solved
  29 % → 38 %.
- On the hidden 26 tasks, the same task took longer with 21 requests in
  flight than with 16: task 12 took 37.7 min at 16, and 50.1 and 52.2 min at
  21.



## The clock runs out before the model gets the answer wrong

We found that the most failures not come from a wrong answer, but comes from the model stuck and can not produce an answer. WHen the model can not solve the problem, it keeps working and reasoning and generating tokens. sometime this behavior blocks other tasks which may be solvable.

**Assignment 5, first trial** (all 89 tasks, thinking on, 24 open):
- 28 solved in 109 min. Of the 61 failures, **49 ran out of time**. Tasks
  where the agent itself declared it was finished passed **26 of 40 (65 %)**.
  So once it got to an answer, the answer was usually right; most failures
  never got there.
- **86 % of a turn was waiting for the model** (32.5 s a turn against 5.4 s
  of running commands). About 7.6 s of it was waiting in the agent's own
  queue for a free server slot, and the remaining ~25 s was the server
  reading the prompt and writing ~886 tokens.
- The tasks that ran out of time wrote 2.6 times as many tokens per turn
  (1,248 against 481): long thinking before every small step. A 15-minute
  task got about 23 turns.


**Assignment 3, the 22 Oct run** (5 provided tasks, a fixed cap of 40 turns):
- 2 of 5 solved. All six attempts hit the 40-turn cap. The model called
  `finish` **0 times in 283 tool calls**: it never decided it was done.
- Only 8 % of calls were edits. The three failures never edited a file
  (empty patches). The two passes made their first edit at turns 17 and 36.
  Nothing told the model it had a budget or how much was left.


**Assignment 2, iteration cap vs wall-clock time:**
- A limit of 120 turns did not bound time: one shell command could take
  180 s. On one of our own tasks the first harness ran until an outside
  55-minute timeout killed it and produced **no patch at all, twice**. With a
  40-minute wall-clock deadline added, it stopped itself and still returned a
  partial patch (10 of 35 tests).


**Assignment 4, tasks starved of turns:**
- Five tasks ran at 89-274 s a turn and got only 20-51 turns. Turning
  thinking off once few turns were affordable: "no patch" went from 5 to 0,
  3 of the 5 were solved, and turns per task-minute went from 1.13 to 2.52.
  It shipped together with three other changes (submission 7, 10/26), so
  this one was not measured alone.




## AI use

For implementing the assignments, I typically used Claude Code to iterrate based on submission leaderboard feedback.
At checkpoints, I ask it to brief me about progress and blockers and I decide on the next direction.
Finally after finishing, the agent brief me about the lessons and system architecture.
