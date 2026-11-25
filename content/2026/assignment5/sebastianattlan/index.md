---
title: "Agents Are a Systems Problem, Not Just a Model Problem"
date: 2026-11-24
authors: ["Sebastian Attlan"]
summary: "Across Assignments 2-5, the biggest time sinks weren't the model but the system around it: cache memory, scheduling, shell exit codes, noisy evaluations, and prompt rules that sounded helpful but cost solves."
tags: ["agent-design", "context-management", "caching", "evaluation", "inference-serving"]
draft: false
toc: true
---

Going from a minimal coding agent to serving my own model on a single 32 GB GPU, the biggest time
sinks weren't the model itself but the system around it: memory, scheduling, shell exit codes, and
whether my experiments were even measuring what I thought they were.

<!--more-->

I'm not sure what you guys were expecting when taking this class, but at least for me I thought
the bottleneck challenges would be around the models themselves: How do we optimize computations?
How do we reduce our compute footprint? Which model can code tasks most efficiently? And yes, this
was definitely a BIG part of it; however, the biggest time sinks for me were systems issues on the
memory and evaluation side of things: memory allocation, scheduling, shell exit codes, and whether
my experiments were even measuring what I thought they were.

Over the course of it all, starting from a relatively minimal coding agent, to serving our own
model on a single 32 GB GPU and running it on 89 fairly diverse Terminal-Bench tasks, I'd say I
learned a lot!

Here's where I ended up:

| Assignment | Best score | Additional metrics |
|---|---|---|
| A2 | 4/10 | SWE-bench Pro |
| A3 | 18/26 | $0.51 and 10:08 per solve |
| A4 | 7/26 | 1h 17m |
| A5 (Terminal-Bench) | 38/89 | 1h 45m |
| A5 (speed-focused) | 36/89 | 1h 17m |
| A5 (26-task benchmark) | 12/26 | 1h 11m |

I debated between going chronologically and going through the lessons in the order that made
sense. In the end I chose the latter, since I wanted to discuss the lessons that came up
repeatedly, particularly the experiments where what happened was quite different from what I
expected. I hope you enjoy!

## 1. Benchmark the workload you’re actually running

When we started serving Qwen3.6-35B-A3B in Assignment 4, I initially suspected that the GPU's
computational throughput would be the primary bottleneck. What I had underestimated was how much
computation went into repeatedly processing the same conversation histories.

An inference server maintains a KV cache, which allows it to reuse computations from previously
processed tokens. This is particularly useful for agents, since consecutive prompts are almost
identical: each new prompt is essentially the previous one plus another tool call and its output.

With 26 agents running simultaneously, however, my GPU's cache was almost completely full within
90 seconds, and only 15% of prompt tokens were being served from it. The cache could hold
approximately 391,000 tokens, whereas the combined conversation histories could easily exceed a
million. Agents were constantly evicting one another's histories and forcing the server to
recompute them.

The standard serving benchmark I was using, which sends independent prompts to the server, showed
throughput of around 12,000 tokens per second but did nothing to expose this problem.

Having learned this lesson in Assignment 4, I proceeded to make essentially the same mistake in
Assignment 5. A benchmark of fresh 31k-token prompts suggested that throughput was relatively flat
between 8 and 16 concurrent requests, so I thought reducing the number of simultaneous agents
might improve per-task latency without substantially hurting overall throughput.

| Concurrent agents | Solves | Runtime |
|---|---|---|
| 16 | 38 | 1h 45m |
| 12 | 35 | 2h 09m |
| 10 | 37 | 2h 36m |

So much for that.

What finally helped was writing a benchmark that simulated actual agents, with growing
conversation histories, periodic context compaction, and four seconds of simulated tool execution
between requests. The tool execution was particularly important, since an agent's history could be
evicted from the cache while it was off running a command.

This led me to SGLang's hierarchical cache, which stores evicted GPU cache entries in CPU memory
rather than discarding them.

| Server configuration | Turns/second |
|---|---|
| Baseline | 0.80 |
| Hierarchical cache | 1.01–1.03 |
| + Longest-prefix-match scheduling | 1.08 |
| + Concurrent request limit | 1.10 |
| Speculative decoding configurations | 0.62–0.78 |

With the tuned configuration, the cache hit rate increased from 71% to 90%. In an actual
leaderboard run with 16 concurrent agents, throughput increased from 40 to 55 turns per minute, and
average turn latency fell from 21 to 15 seconds. The run also finished 28 minutes earlier, although
I had reduced the per-task time limit at the same time, so not all of that is the cache.

Interestingly, speculative decoding, which made generation about 30% faster for a single request,
made the actual agent workload slower because of its additional memory requirements.

I would have saved myself several leaderboard submissions had I written a realistic serving
benchmark at the beginning of Assignment 4.

## 2. It’s surprisingly difficult to tell whether a change helped

With only two leaderboard submissions per day, I frequently found myself making a change,
submitting it, and deciding whether to keep it based on a single result.

As it turns out, there's quite a bit of variance in these results. Across five Assignment 5 runs
with essentially the same harness and relatively minor configuration changes, the tasks broke down
as follows:

| Outcome | Tasks |
|---|---|
| Always solved | 18 |
| Never solved | 41 |
| Sometimes solved | 30 |

About a third of Terminal-Bench consisted of tasks that my agent was demonstrably capable of
solving but couldn't solve consistently. Even the exact same submission, graded twice, solved 38
and then 37 tasks, with 13 tasks differing between the two runs.

I saw something similar in Assignment 3, where my first three runs collectively solved 18 distinct
tasks, despite no individual run solving more than 15. In Assignment 5, seven closely related
versions of my agent scored anywhere from 28 to 38, with a mean of 33.6.

This made interpreting small improvements quite difficult. A two-task increase might have been the
result of a better prompt, or it might have had absolutely nothing to do with my change.

I eventually started paying considerably more attention to intermediate metrics and individual
trajectories. Did the agent take fewer turns? Did it finish tasks earlier? Did the change actually
eliminate the failure mode I was targeting?

In retrospect, spending two early submissions grading the same baseline would have been a pretty
good use of my limited submissions, since it would have told me how much weight to put on
subsequent results.

## 3. Tokens are free, but time isn’t

One of the more counterintuitive improvements I made was turning off extended reasoning.

In Assignment 3, I occasionally watched the model generate close to 16,000 reasoning tokens before
deciding to read a file. Given that reading a file is cheap, reversible, and likely to give the
model more information, it's not clear to me what it gained from thinking about it for so long.

Disabling reasoning took my score from 16 to 17 while reducing the time per solve from 9:57 to
7:45. In Assignment 4, enabling thinking increased the median turn latency to 74 seconds, compared
to 29–43 seconds in other configurations, and resulted in only two solves. Eight tasks ended
without even producing a patch.

My initial mistake was measuring the cost of reasoning on a toy prompt rather than considering what
happens when you insert that overhead into a loop that runs hundreds of times.

Another interesting result was that, beyond a certain point, improving server throughput barely
affected total runtime. After enabling hierarchical caching, I made two additional optimizations
that improved my benchmark from 1.03 to 1.10 turns per second, yet all three leaderboard runs
finished within two minutes of one another.

Looking at where the time went explained why: in one run, 848 of 1,065 task-minutes were spent on
tasks that ultimately failed. Many of these tasks continued until they hit their time limits,
regardless of how many turns they managed to take.

Reducing the per-task time limit helped, although at the expense of some solves:

| Solved within (minutes) | Average solves |
|---|---|
| 6 | 19 |
| 10 | 28 |
| 16 | 31 |
| 20 | 34 |

What I'd really like to figure out is whether, ten minutes into a task, we can distinguish an agent
making legitimate progress on a difficult problem from one that has spent the past ten minutes
going down a rabbit hole. A shorter universal timeout simply trades accuracy for speed; identifying
unproductive trajectories could potentially improve both.

## 4. Compaction and seemingly helpful prompt changes

I tried more aggressive context compaction on several occasions throughout these assignments, with
remarkably little success.

The motivation was that an agent probably doesn't need to see the entirety of a file it read fifty
turns ago, and removing old tool outputs should make subsequent requests cheaper and faster.

In Assignment 3, lowering the compaction threshold from 110k to 48k tokens took my score from 17 to
11, with some agents reaching over 220 turns as they repeatedly reread files. In Assignment 5,
earlier compaction took my score from 38 to 30, increased the number of turns by 6%, and didn't
even make those turns faster. Moving the threshold in the opposite direction gave me 28 solves.

Compaction also has a less obvious cost: modifying an earlier part of the conversation invalidates
the cached computation that follows it. In Assignment 3, uncached input tokens were approximately
20 times as expensive as cached ones, so I was potentially increasing costs while trying to reduce
them.

My favorite example of an ostensibly helpful change, however, was a single addition to the system
prompt.

The Terminal-Bench paper identifies missing programs as roughly 24% of command failures, so I added
an instruction telling the agent to check whether a program existed using `command -v` and install
it if it didn't.

My score went from 38 to 28.

Many of the regressions occurred on build tasks, where I suspect the agent was installing packaged
binaries instead of building the programs the tasks actually asked for. One task that had been
solved in four consecutive runs took 80 turns and failed. Removing the instruction brought my score
back to 37.

I had more success with changes targeted at specific failures. In Assignment 2, instructing the
model to follow nearby code conventions and register a check for each stated requirement improved
one troublesome task from 1/8 to 4/4 successes.

My best Assignment 5 improvement, from 31 to 38 solves, came from changing the sampling parameters,
imposing an 8k-token response limit, and introducing a stricter verification step. Unfortunately, I
changed all three at once, so I can't tell which was responsible.

## 5. Some instructions belong in the harness, not the prompt

In Assignment 2, my agent could register commands to verify that it had completed a task, and the
harness wouldn't accept its declaration of success unless those commands passed.

This worked quite nicely, except that the agent frequently registered checks of the form:

```bash
pytest ... | tail -5
```

By default, the exit status of a shell pipeline is that of its last command, so I was verifying
that `tail` had successfully displayed some text rather than that `pytest` had passed. Four of the
fourteen checks I examined were affected.

The fix was to inspect the exit status of the command that matters:

```bash
pytest ... | tail -5
test_status=${PIPESTATUS[0]}
```

I ran into several other cases where something that seemed like a reasonable instruction to give
the model would have been much better implemented directly in the harness.

Despite explicitly telling the agent not to modify test files, one run produced a patch that was
52.8% test modifications, which the official evaluation then discarded. I changed the tools to
reject edits to test paths.

On another occasion, the agent committed its changes, leaving my patch extraction with an empty
diff. I fixed this by extracting patches relative to a fixed baseline, and also started collecting
patches even when the agent hadn't declared itself finished (two of my four Assignment 2 solves
actually ended on the token limit).

Verification itself remained difficult. In Assignment 3, grader feedback let me recover two of
seven failed tasks for about three cents each. Without that feedback in Assignment 5, I asked the
agent to perform increasingly strict checks before accepting early declarations of success.

Even then, roughly six tasks per run declared themselves finished within 7.5 minutes and then
failed the evaluation. Writing additional tests only helps insofar as those tests reveal something
the model doesn't already believe about its solution.

## 6. Budget for what you’ve committed, not just what you’ve spent

My first Assignment 3 run solved 12 of its first 19 tasks and exactly one of its last seven,
largely because there was barely any money left by the time it reached them.

With multiple agents running concurrently, tracking money already spent isn't enough, since there
may be several expensive requests in progress and a number of tasks that haven't even started.

I implemented a ledger that reserved the expected cost of active retries, along with $0.12 for each
unopened task, and went from 14 to 16 solves. Adding a cheaper retry before the more expensive one
eventually brought me to 18 solves at $0.51 per solve.

My reservation estimates were still too conservative: I budgeted $0.15 and $0.65 for retries that
actually cost closer to $0.03 and $0.40.

I ran into a similar allocation problem in Assignment 4. Letting agents keep retrying failed tasks
left 21 agents running after an hour, even though nothing was solved after minute 35. Stopping
after two unimproved retries, on the other hand, left about half an hour unused. Both policies
solved five tasks; an intermediate policy solved seven.

Giving one agent another attempt at a task may be worthwhile in isolation, but much less so when
that agent is competing with 25 others for the same GPU.

## 7. A lot of my failures had nothing to do with the model

Some of my more frustrating experiments failed for fairly mundane reasons:

- In Assignment 2, an agent passing 59 of 66 tests used up all six of its connection retries in 33
  seconds, with 25 minutes still remaining. I now bound retries by time rather than count.
- Running out of disk space on my laptop silently truncated source files to zero bytes, breaking
  every evaluation container.
- In Assignment 3, I ran three experimental configurations at once without accounting for the fact
  that they shared an eight-request API limit and the same budget. Only one of the three produced
  usable results.
- In Assignment 4, my automatic submission timer died when my session ended, costing me both
  leaderboard submissions for the day.

None of these are particularly interesting technical problems, but given how few chances we had to
evaluate our agents, they ended up being quite expensive mistakes.

## In the end…

By the final day of Assignment 5, the Pareto front included submissions solving 72 tasks in 87
minutes and others solving 39 tasks in just seven minutes (I'm particularly curious about the
latter). My best results, 38 solves in 105 minutes and 36 in 77 minutes, were quite far from either.

If I were starting again, I'd build an agent-shaped serving benchmark on day one, grade the same
baseline twice, keep per-task results for every experiment, and resist the temptation to implement
several seemingly good ideas at once.

What surprised me most throughout these assignments was how much I could improve (or worsen) an
agent without changing its underlying model. One prompt instruction cost me ten solves, a cache
setting substantially increased throughput, and a shell exit code made my verification much less
useful than I thought it was.

I suspect that as models get better, figuring out how to allocate their time, manage their
context, and reliably evaluate their work will remain an interesting problem in its own right. But
who knows? If AI solves the Riemann hypothesis, maybe we won't need to work at all in the near
future!

## AI use

I used Claude Code as a coding assistant for the agent harness, the serving experiments and the
leaderboard runs across Assignments 2–5, and to format and proofread this post and check its numbers
against my run logs. I wrote the words, then Claude also formatted everything into this post!
