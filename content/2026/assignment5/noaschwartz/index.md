---
title: "Working backwards from the traces: what I learned optimizing an agent stack"
date: 2026-11-23
authors: ["Noa Schwartz"]
summary: "Verify that a change actually ran, know what your local benchmark can't see, and work backwards from where the time goes: lessons from building, optimizing and serving a coding agent across Assignments 2-5."
tags: ["local-benchmarks", "agent-harness", "serving-metrics", "prefill-decode", "kv-cache"]
draft: false
toc: true
---

Quick summary of what we learned for each

- **A2, Mads-Loop:** Built a basic agent loop on the course model API: call the model, run tools, feed results back. Learned that context management and tool design shape agent behavior as much as the model does.
- **A3, Mads-Opt:** Made the A2 agent cheaper by cutting tokens. Learned to treat tokens as a budget and to trade cost against task performance.
- **A4, Mads-Serve:** Ran an open-weight model on our own serving engine on the course GPUs. Learned how batching, scheduling and KV-cache/prefix reuse set throughput and latency.
- **A5, Mads-Stack:** Optimized the whole stack, from agent down to engine, with routing, quantization and speculative decoding. Learned that choices at one layer change what pays off at the others.

<!--more-->

## Limits of local traces

### Challenges with creating a driver to iterate recursively on local tasks

Idea: I wanted to build a driver that proposes a change to the engine or agent harness, runs the 25 local tasks on a GPU, compares the result against the best configuration so far, and keeps or reverts the changes. Then have this repeat unattended overnight.

Problem 1: The Driver makes changes and claims they are implemented or applied in cases where this isn't true. One engine patch in A4 changed how the prefix cache evicts dead branches. A run with it scored 16/25 and attributed the improvements to this change.

Much later, while analysing cache logs, I found that every server log said `impl=UnifiedRadixCache`. The patch modified `MambaRadixCache`, a class this model never uses. The patch had never run once. The "16/25 engine" was really one flag, and the 16/25 was a lucky draw. Its cache-loss rate was no better than the base engine's.

**Lesson:** checking the outcome isn't enough; check that the mechanism actually ran. Each change should come with a cheap proof it's active: a log line, a counter, a changed metric. The driver should refuse to score a change without it.

Problem 2: The local benchmark has different bottlenecks than the actual leaderboard. For example, I tested hierarchical caching (hicache) with a full local run. It cut model time by half and also decreased the turns that lost their cache by half, but the run was 3 minutes slower, so the driver reverted it.

Digging in showed the task sandboxes all ran on one 4 vCPU box, 25 at once. A faster model sends agents back to their build tools sooner, so more Go builds overlapped. Tool timeouts rose from 49 to 65 calls, and run time is set by the slowest task. The engine improvement showed up as a loss because of a bottleneck only our local setup had: on the leaderboard, each task container gets its own core.

**Lesson:** know the limits of the local benchmark and what constraints the leaderboard also has. Pick the decision metric to match what the change targets: judge engine changes on model time and cache behaviour, and agent changes on solved count.

## Harness changes beat engine changes

Harness changes were the primary way to increase tasks solved on hidden tests, more than the serving engine.

### Harness changes

There are a lot of decisions around harness control flow that I didn't realize an advanced coding harness like Claude Code was doing under the hood. And it's interesting to me how the evolution of Claude specifically came about (i.e if the harness self-improved over time, vs time spent debugging traces to understand where lessons like the agent saying a task is done is an unreliable one). Some interesting harness changes:

- **A4: one fresh-context retry.** When a task's first attempt fails grading, the harness starts a second attempt in a brand-new conversation. It starts from the task statement again, not from the failed chat, and the better of the two attempts is kept. Model output is random, so a second attempt from scratch can land on a different, correct approach. Fixing the failure in the same chat tends to repeat the first attempt's wrong assumptions.
- A4: early retries. A failed task normally waited for its grade before retrying. Grading was a slow queue that ran only 3 at a time, so engine slots sat empty during that wait. Run 1042 had 107 idle slot-minutes. Early retry starts the retry right away, before the grade comes back, but only after every task has been opened once, so retries never delay first attempts. If the grade comes back as a pass, the retry is cancelled. Retries started about 15 min earlier, leading to faster runs (same score). Across runs, there was only around a minute of "wasted" work from cancelled retries.
- A3: budget nudge and step warnings. The model couldn't see how much of its budget was left. In run 10, an Expert attempt spent 22 of its 23 steps reading code. Its only edit came after it had already gone over its $0.30 cap. I made 2 changes here: (1) at 8 steps left, the model is told to finish and call `done`; (2) if half its steps are used and it has changed no code, the model is told to stop exploring, make its best fix, test it, and finish.

![Two timelines for a task whose first attempt fails. Without early retry, the task waits for its grade while its engine slot sits idle, then the retry runs. With early retry, the retry starts as soon as the first attempt ends, while grading happens alongside, so the retry finishes earlier and the slot never idles.](early-retries.svg "Figure 1. Early retry starts the retry while the first attempt is still being graded, so the engine slot stays busy and the retry finishes earlier. Illustrative, not to scale. If the grade comes back as a pass, the retry is cancelled.")

### Engine changes

I think engine changes are valuable when they're extremely targeted to a known bottleneck that you can consistently see across runs - i.e in A4 the KV cache was consistently 97% full while the mamba state slots never went above 47% used.

Moving memory from the slots to the KV cache (controlled by this flag `--mamba-full-memory-ratio` which defines how GPU memory left after loading the model weights is split between the model's two caches) meant conversations stayed cached between tool calls. Changing this from the 0.9 default to 0.5 meant re-prefilled tokens fell from 12.9M to 5.9M, and calls went from 20.5 s to 9.9 s, and solves went from 10/25 to 16/25!

One thing I didn't get a chance to investigate but would consider is how to increase concurrency beyond \~12 by taking advantage of the fact that while a model serving a certain task sits idle when a tool call is in progress and the model can go serve a different task at the same time.

## What makes a serving engine good

Good depends on the workload. Efficient serving is tied to the shape of the traffic, so constantly monitoring the workload shape (and doing an initial set of runs to understand workloads before you begin optimization) is critical.

### Metrics that matter for agentic traffic

Most public engine benchmarks report throughput and time to first token on independent prompts. For agentic systems, the numbers that matter are different:

- hit rate on a returning conversation after a pause of N seconds;
- per-stream decode speed at low batch, which sets the long tail (A5: \~160 tok/s at 1 request, \~500 tok/s total at 10);
- how memory is split between KV and Mamba state slots;
- behavior as load rises.

### Robustness and observability

Robustness and observability: Throughput and time to first token on a benchmark don't tell you whether an engine will:

- **Maintain a 2–4 hour run when server briefly loses connection:** when my server froze for about 3 minutes in R1, I lost 6 of 25 tasks at once, and in A4 my rerun lost every model call from 18:40 on;
- **telling slow apart from stuck under heavy load:** Under heavy load (many tasks' model calls running on the GPU at the same time), my calls slowed to 1.5–7.7 tok/s but kept producing tokens. My fixed 300 s cap killed any call that ran longer than 300 s, so it treated these slow calls as stuck and ended 10 tasks early.
- **make sure metrics are properly defined and tracked:** I tracked `cached_tokens` as my cache hit rate, but on this hybrid model it only counts the prefix reused up to the last saved Mamba state snapshot, so a low value didn't necessarily mean my KV cache was evicted and I couldn't properly diagnose why turns were so slow - i.e if it was because it lost its KV cache to eviction or just its Mamba state snapshot. Those two problems need different fixes.

### How to compare engines

How to compare engines:

- Judge an engine change by its own metric: call latency, cache hit rate, re-prefill - not by local end-to-end time, which the CPU, the harness and noise can muddy results.
- Measure it on traffic that will actually represent the agentic system it will be serving. For example, agentic systems have traffic with more pauses due to tool calls.

## Cache misses and full caches


**Where task time goes.** Debugging cache behavior requires finding patterns in how task time is being used. In A5, I noticed that consistently across local runs, model calls were the largest share of task time. A model call, or a single request (also known as roughly one agent turn), is defined as 1 chat-completion request from the agent to our server (POST /v1/chat/completions). All runs saw that model calls took up \~74% of task time, and digging in further, I noticed decode took 81% of that (ttft was 19%).

**Why decode was slow.** In some of the initial replay benchmarks (i.e just testing the speed of a single request at a time), responses were generated at 168 tok/s, which serves as a pretty good benchmark for the fastest this model can write to the GPU. But in the real runs, where many agent tasks were opened at once (12), decode was closer to 55 tok/s. Thus, something was making decode very slow when multiple tasks were being served. The reason here was that another request's large prefill was running at the same time, so the slowest 5% of calls took 36% of model time.

![Two timelines of one task generating tokens. Alone on the server it generates a steady stream of tokens at about 168 tokens per second. When other tasks send large prefills, it stops generating until each prefill is done, so while tasks overlap it averages about 55 tokens per second.](decode-stalls.svg "Figure 2. Decode was slow only when other tasks' large prefills overlapped it. Illustrative, not to scale.")

**Ruling out a full cache.** From there, I tried to understand why there were so many large prefills happening mid-conversation - i.e in most examples across runs these were mid-conversation cache misses. The obvious reason for this might be that the cache was full, which would be true if we saw long pauses between calls (\~30s), but I saw idle time was much smaller (closer to \~1s) and happened most commonly when concurrency was high (note NOT same as # of open tasks - concurrency is # of requests server is processing, or how many calls are sent to server / in-flight at once). Higher concurrency means more requests are sharing the same GPU and same KV cache pool, and more prefills need to fit between decode steps.

**Two kinds of misses.** Lesson here was that we have 2 types of miss classes: (1) capacity eviction: Task's history is evicted while it sits idle and the KV cache fills up. - you can add more KV, offload, or have fewer open tasks, or (2) Misses with no idle time where the task's history is lost seconds after it was last used.

![A header defines a call as one request from the agent to the server, which resends the whole conversation so far, with the agent running a tool and the task idle between calls. It explains that the KV cache holds the attention keys and values for every token so far in one pool shared by all tasks, the Mamba state is a snapshot of the model's running state saved after a turn in its own slots, and the next call can skip re-prefilling the history only if it finds both. Two panels then show each one task's turn, a pause for a tool call, and the next turn, above the KV cache and the Mamba state slots. In the first panel the task idles for a long time, the KV cache fills with other tasks, and the task's KV entries are evicted while its Mamba state is still saved. In the second panel the task idles only about a second, its KV entries are still there, but its Mamba state was evicted from its own separate LRU list. Either way the whole conversation is re-prefilled.](cache-misses.svg "Figure 3. The next call from a task reuses its history only if both its KV entries and its Mamba state are still cached. It can lose either one: capacity eviction of the KV entries (A), or eviction of the Mamba state from its separate LRU list (B).")

**Why speculative decoding wouldn't help.** I thought this methodology of working backwards from where the latency is used was helpful because my instinct was to try to use MTP speculative decoding to speed up decode (and decode was 81% of call time). But instead decode was slow because it was stalled by re-prefills after cache misses. This slowness was other requests' prefills holding up the server (only existed when tasks overlapped) so MTP which would help with per-token cost wouldn't have helped. In fact, it would've made it worse because the speedup comes from using more of the KV pool. In our case that would have caused more misses, and more stalling.

**The real cause.** In this case, the misses were due to the way the hybrid model's saved MAMBA (SSM) states were evicted: they have their own LRU list which is separate from KV cache. When a task's saved state is evicted, the history couldn't be used even if the history KV tokens were still there. So the whole convo had to be prefilled!

**Takeaway.** This was all a long explanation to say that working backwards as follows is helpful:

- Is the time in decode or prefill? Mostly decode.
- Is decode slow by itself, or because of something else? It drops when another request's large prefill overlaps.
- Where do the large prefills come from? Cache misses.
- Which kind of miss? Not regular cache eviction due to full cache, so there must be another reason for cache misses. KV cache and SSM states (in hybrid models) have different caching policies that need to be debugged.

## AI use

As the [course policy](https://cs2680.com/policy.html#ai-policy) requires: I used Claude (via Claude Code) to help build and run the experiment driver and to analyse traces and logs. The measurements and conclusions above come from my own runs, and I checked the results against the logs. Claude helped tidy it up and fix typos.
