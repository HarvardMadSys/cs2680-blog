---
title: "Plan first, protect the KV cache, test twice: what I learned in Assignments 2-5"
date: 2026-11-24
authors: ["Jacqueline Pan"]
summary: "Lessons from the agent side, the server side and the testing side. Plan-then-execute and a done gate helped the agent, giving the KV cache more room helped the server, and repeated runs plus per-task times on the leaderboard showed me which of my wins were real."
tags: ["agent-design", "caching", "testing", "observability"]
draft: false
toc: true
---

In Assignments 2-5 I built a coding agent, made it cheaper, served its model on one GPU, and then tuned everything together. I split what I learned into three parts: the agent side, the server side, and the testing side. If I had to pick one, the testing side taught me the most, because it showed that many of my "improvements" were not real.

<!--more-->

## Part 1: The agent side

### Plan first, then execute

This was the agent change that helped the most. Before the agent is allowed to edit anything, a read-only planner reads the code and writes a short plan (18 steps, at most 8 minutes, only read tools). Then the normal attempt starts with the plan pinned in its context.

I got here after rewriting the prompt did nothing. My failure analysis showed the agent often misread the task, for example skipping a clause or using a wrong name, even though the prompt already warned about these. So I tested each idea in paired runs on 33 attempts:

| Change | Changed | Baseline | Note |
|---|---|---|---|
| Shorter prompt | 17 | 20 | only 2% fewer prompt tokens |
| Add 5 common failure reasons | 16 | 15 | 14% more tokens, twice as many done rejections |
| Turn on thinking | 21 | 19 | 15% slower |
| Deeper planner (30 steps, 12 min) | 20 | 21 | |
| **Read-only planner first** | **24** | **18** | almost no extra time |

Only the planner showed a clear gap, and on the leaderboard it gave 14 of 26 in 1 h 23, my best single-pass result at that time (the three submissions before it had 11-12). Changing the flow did more than any wording I tried.

### A done gate, kept cheap and correct

In Assignment 2 the agent once wrote the correct fix, then ran `git stash` and `git checkout` to "look at the original code", and submitted an empty patch. So I made the shell refuse git commands that discard changes, and I added a done gate: a check that runs when the agent says it is finished, refuses an empty diff, and gives back a checklist from the task description. That fixed those tasks. But the gate needs measuring too. In Assignment 4 one task's check timed out 6 times at 240 s, and after I made it compile only the broken packages and rerun only the failed tests, the batch went from 2894 s to 1708 s. I also found a path bug in the gate that caused 47 of its 95 rejections, so the agent was right and my own check told it to keep working.

### Running tasks in parallel mattered a lot in Assignment 4

In Assignment 4 almost all the time of a run is the agent working. Agents were waiting on the model 78% of the time, and grading a patch at the end is short. So the run time is mostly decided by how many agent conversations the server can run side by side.

My Assignment 3 flow ran two samples of the same task and took whichever passed first. On a shared GPU this was wasteful: the second sample usually ran to the end before it was cancelled, so half the compute was thrown away. I changed to one conversation per task and used the freed capacity to open twice as many tasks.

| Flow | Solved (batch of 16) | Leaderboard |
|---|---|---|
| Two samples per task | 14 and 12 | 12 of 26 in 2 h 15 |
| One conversation per task, 2x tasks open | 12 and 14 | 12 of 26 in 1 h 32 |

Same number solved, 21% to 49% less run time locally. The limit on parallelism is the KV cache, which is the first topic in Part 2.

### Read the failing tests before tuning

In Assignment 2 my agent failed the same 3 of 10 SWE-bench Pro tasks whatever I changed. When I read the hidden tests, all three wanted something the task description did not say. One needed the error message to contain the exact words `or at`. With the requirements and interface text given to the agent, the other 7 passed. I was tuning for tasks that could not pass.

## Part 2: The server side

### The KV cache was the bottleneck

Each task is a long conversation. The server keeps the earlier part in the KV cache, so the next turn only processes the new tokens. This only works while the conversation is still in the cache.

My first Assignment 4 run kept 26 tasks open at once. The cache could not hold them, so they kept pushing each other out.

| Open tasks | Prefix hit rate | Solved | Samples cut off by the time limit |
|---|---|---|---|
| 26 | 0.07-0.10 | 10 of 16 | all 32 |
| 6 | 0.83-0.97 | 13 of 16 | none |

With 26 open tasks almost every turn processed its whole prompt again, and requests spent 53% of their time in the queue. I repeated the mistake in Assignment 5: submission #3 kept 28 tasks open, solved the same 8 tasks, and took 6763 s where the earlier run took 2764 s.

### The flags and tricks that gave the cache more room

Once I knew the cache was the problem, most of my useful server changes were ways to fit more conversations in it.

| Trick | What it does | Result |
|---|---|---|
| `--enable-hierarchical-cache --hicache-ratio 1.5` | moves evicted prefixes to host RAM and loads them back, so they are not computed again | replay prefix ratio 0.80 to 0.95, TTFT p95 13.0 s to 1.7 s |
| `--mamba-radix-cache-strategy extra_buffer_lazy --mamba-full-memory-ratio 0.6` | my model is a hybrid, and GPU memory is split between mamba state slots and the KV pool. This gives fewer slots and more KV | KV 391k to 465k tokens |
| Do not load the vision tower | the agent only sends text, so 0.83 GiB of vision weights are not needed | KV 264k to 327k tokens, same decode speed |
| Prefill CUDA graphs only up to 512 tokens (was 4096) | frees about 0.7 GB | KV 346k to 395k tokens, mean request time 20% lower |

The first two together were my final Assignment 4 config. On real tasks:

| | Before | After |
|---|---|---|
| Prefix hit rate | 0.81 | 0.96 |
| Tokens processed again | 13.6M | 3.7M |
| Time per output token | 38 ms | 21.6 ms |
| Run time | 3450 s | 2555 s |

Some things did not work:

- `--kv-cache-dtype fp8_e4m3` changed nothing, because the checkpoint already used fp8 KV. The startup log printed 391,068 tokens every time and I did not read it.
- `--mamba-full-memory-ratio 0.9`, to run all 26 requests at once, went the wrong way: KV fell back to 391k, prefix hit 0.82 to 0.70, queue time 6.0 s to 9.3 s per request.
- The default `--hicache-ratio 2` did not start, because it needed more pinned RAM than the machine had.
- Squeezing memory too hard crashed the server. One config started with about 0.6 GB free, loaded about 0.5 GB of kernels later, and ran out of memory after 12 minutes.

### A small pitfall: speculative decoding with default flags

In Assignment 4 I turned on speculative decoding (the checkpoint's MTP head drafts a few tokens and the main model checks them) with only the basic flags. Decoding was 9% to 35% faster, but the KV pool dropped from 465k to 247k tokens, the server ran 4-6 requests at once where it had run 21, and it crashed together with the hierarchical cache. I decided it was useless. In Assignment 5 I found that the problem was the defaults and not the technique. The draft kept its own KV cache in bf16, which took half the pool and did not match the fp8 layout the hierarchical cache expects. My model is also a hybrid, and it saved an extra state for every draft token, which used up the slots that limit how many requests can run. With `--speculative-draft-kv-cache-dtype fp8_e4m3`, `--enable-linear-replayssm-spec` and an fp8 draft head, plus the memory tricks above, it ran 23 requests at once with 346k-395k tokens of KV and the hierarchical cache on. I should have read where the memory went before giving up on it.

## Part 3: The testing side

### Run everything more than once

The same configuration gives a different score each run. In Assignment 4 one unchanged setup solved 11 to 14 tasks locally and 14 to 19 of 26 on the leaderboard. I also ran an A/A test, where both arms are identical, and TTFT p95 still moved by 15%.

I knew this and still got fooled in Assignment 5. Submission #2 scored 21 and 21 of 30 locally, better than my baseline, so I submitted it. On the leaderboard Terminal-Bench 2.0 dropped from 36 to 27 of 89. When I ran the same config again locally it got 18 and 19. The two 21s were luck. Now I run each configuration at least twice, next to baseline runs from the same day, and I do not believe a gap of one or two tasks.

### Change one thing at a time

Ablation matters for the same reason. The prompt table in Part 1 only makes sense because each row changes one thing and is compared with the same baseline in a paired run. It is slower, but without it I would have kept the shorter prompt and thinking mode just because they sounded right.

A random benchmark was also not enough. With random prompts I only saw "decoding takes most of the time". Real agent requests were about 26k input tokens (median) and reused the previous turn as a prefix, which is exactly the cache problem in Part 2. Replaying recorded conversations was closer, but the replay was too small to fill the cache, and it rejected the cache config that later cut my real run from 3450 s to 2555 s. Benchmarks helped me understand the mechanism. For the final decision I had to run real tasks.

### My local wins were probably overfitting

I tuned on a small local set: 17 tasks for Assignment 4 and a 30-task subset of Terminal-Bench. After many rounds of picking whatever scored best on these same tasks, I think part of what I kept was fitted to them and not real improvement.

| Change | Local result | Leaderboard result |
|---|---|---|
| #7: compress context from 32k to 20k tokens | 13 and 12, baseline 10, 12, 10 | 26 of 89 (33 before) |
| #8: accept the first done without the checklist | 11 and 13, baseline mean 10.7 | 9 of 26 |

Both looked better locally with repeated runs, and both were worse on the tasks I had not tuned on. My subset was also easier than the rest: on the leaderboard I solved 19 of those 30 tasks and only 17 of the other 59. So a change that helps on my subset tells me less than I thought. If I did this again I would keep some tasks that I never look at while tuning, and only use them for the final check.

### Look at the time of each task on the leaderboard

The total score hides a lot. The per-task times were more useful to me, twice.

**All tasks ended at the same time.** In my first Assignment 4 submission, nearly every task closed at almost the same minute. Tasks do not all finish together by themselves, so the time limit had cut them off. This is how I found the cache problem in Part 2 before I had any server metrics.

**Long tasks were rarely solved.** In my first three Assignment 5 submissions I grouped the Terminal-Bench tasks by how long they ran. Tasks that ran over 15 minutes were solved 13% of the time (11 of 86). Shorter ones were solved 51% of the time. So I set a 15-minute limit per task:

| Limit per task | Solved | Run time |
|---|---|---|
| none (earlier submission) | 34 of 89 | 6483 s |
| 15 min (submission #4, also added speculative decoding) | 30 of 89 | 2567 s |
| 15 min (submission #5) | 33 of 89 | 2302 s |
| 20 min (submission #10) | 34 of 89 | 3243 s |

Raising the limit from 15 to 20 minutes added 941 s and one solved task. In that run 28 tasks went over 15 minutes and only 3 of them were solved. Most of the extra time goes to tasks the agent will not finish anyway.

## AI use

I used Claude Code throughout Assignments 2-5 to write harness code, run and monitor experiments, track the leaderboard, and keep the run logs. 
