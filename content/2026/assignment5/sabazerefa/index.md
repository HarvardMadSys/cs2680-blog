---
title: "From solve rate to speed: what I learned building an agent harness"
date: 2026-11-24
authors: ["Saba Zerefa"]
summary: "Offline scores were a noisy guide to solve rate but a reliable one for speed. The biggest speedups came from keeping the KV cache warm, and the biggest process lesson was to have my coding agent change one thing at a time and measure it."
tags: ["agent-design", "caching", "evaluation", "serving"]
draft: false
---

Across Assignments 2-5, my harness work moved from getting the agent to solve more tasks to
getting it to solve them fast. Along the way I learned to trust only measured, isolated
changes, both in the harness and in how I directed my own coding agent.

<!--more-->

## Early assignments: Strengthening harness solving capabilities

Assignment 3 was my weakest. Early in the assignment, I was overreliant on the offline set
when having my agent make changes, which, as I came to know deeply well, was a poor indicator
of task success rate on the leaderboard. Many repeated submissions were necessary to decipher
noise vs. signal in submission quality, with rank correlation between my offline and online
solve rate being ~0.4. Comparably, I found the time solved and costs were better correlated
between offline and online sets. I attempted to build more "accurate" offline benchmarks using
other subsets of SWEBenchPro, but they did not correlate better with online performance.

A core issue of Assignment 3 is the relationship between Expert and Standard (I found
virtually no utility in the Starter model). I found the Expert alone to have a 4/5 average
solve rate offline on my "toss-up" tasks, while Standard had an average of 2/5. I experimented
with various versions of Expert "handing off" tasks to Standard, with resulting scores of
~2.5/5, a marginal improvement given the affiliated ~$.40/task cost increase. Having Expert
restart on Standard failures allowed for a happier medium.

To mitigate costs and assist with redos, I initially attempted to hand information from prior
runs to the retrying agent. Although this did reduce cost compared to clean restarts, I found
it often biased the retrying agent and led to lower-quality retries. I also created heuristics
to assess task difficulty, to better allocate retrying effort. After some experimentation on
the offline set, I found that no retries (0/16) succeeded if more than 2/3 of tests failed at
the first grade, yet nearly all were recoverable if <1/3 of the tests failed. I adjusted
retrying efforts accordingly, allowing for retries by Expert for failures that seemed close to
success as gauged by passing rate. Furthermore, from Assignment 2, I had implemented review
sessions pre-grading, as motivated by some easily-reviewable errors; however, this wasted
effort and yielded no meaningful information that couldn't be achieved from grading, saving
0/9 toss-ups. Additionally, before Assignment 4, after witnessing the Assignment 3 speakers, I
also implemented other critically acclaimed harness features such as done gating/verification.

## Later assignments: Need for speed

Due to Assignment 4's focus on speed, the offline set was more useful in anticipating
leaderboard success, making the harness iteration process more predictable. My initial run
achieved 9 solved in 4 hours, due to maximal task parallelization as inherited from the
Assignment 3 harness. The cache hit rate under this paradigm was ~2%. Cache hit rate was
extremely high (98+%) starting at batch size ~6; doing a sweep of total solve rate vs. batch
size allowed me to achieve the baseline.

Further optimization experimented with other ways of increasing task efficiency, mostly by way
of experimenting with engine flags. Releasing the default prefill graph capture allowed KV
cache capacity to increase from 391k to 630k tokens, and limiting Mamba states per task helped
decrease recompute share from 55% to 13% and first-token wait times, allowing for 17/25 to
21/25 tasks solved in the same 36 minute cap on the offline set. Furthermore, I made other
general changes to reduce token generation, like turning thinking off (responsible for 73% of
generated tokens with no meaningful difference in solve rate), and capping concurrent
conversation, which reduced cache load and repeated refill. The above was achieved as a result
of careful and isolated iteration, verifiable improvements, and reversions upon failed
attempts.

Due to a relatively robust Assignment 4 harness and more relaxed baseline criteria,
Assignment 5 implementation was a generalization of Assignment 4 with minimal additional
experimentation with per-task time capping.

## Lessons learned in agent usage

The main pitfall I experienced in the early assignments was overweighing my intuition and not
requesting verifiable results. The agent was susceptible to making a myriad of simultaneous
changes, and without isolated tracking of the effect of each constituent change, I often
implicitly misattributed a positive effect to the more intuitive/sensical harness change,
which was not always the case. This was most apparent in the Assignment 3 workflow with the
aforementioned retrying paradigms. In later assignments, I ensured the agent had iterative
changes and notetaking with rigorous metrics justifying their existence.

## AI use

As the [course policy](https://cs2680.com/policy.html#ai-policy) requires: I used Claude Code
as my coding agent across the assignments, plus Codex for one session. Under my direction it
wrote and ran the harness and serving changes, the experiments and the analysis scripts behind
the numbers above. The post text is my own; Claude Code wrote the title, summary and opening
paragraph from my draft, formatted it for this blog and opened the pull request.
