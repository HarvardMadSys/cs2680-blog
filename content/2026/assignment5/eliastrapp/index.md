---
title: "Learning what actually works: Lessons from A2-A5"
date: 2026-11-25
authors: ["Elias Trapp"]
summary: "Across four assignments building coding agents and their inference systems in CS2680, I learned how easily noisy leaderboards, misleading local tests, and isolated benchmarks can make a change look better than it is. This post reflects on those mistakes, together with some hard-earned lessons, and describes why sometimes \"simple and fast\" beats unnecessarily complex."
tags: ["agent-design", "context-management", "observability", "inference-serving", "benchmarking"]
draft: false
toc: true
---

In the following, I describe some valuable lessons I learned while dealing with the assignments in CS2680:


## Lesson 1: Dealing with noise on the board

Throughout assignments 3-5, I noticed significant variation on the number of solves gained. Seen for the first time in A3, I had the same submission draw 9 once and 13 another time. This made it very difficult to understand whether a change made was actually going into the right direction, particularly in A3. Similarly in A4, I had the same submission draw 14, 13, and 10 solves; in A5, the same zip drew 42 and 36 on Terminal-Bench, and 16 and 11 on the 26 tasks.

Following the course staff's tips, I began measuring the solve spread beginning in A4 by redrawing the same submission multiple times to see whether a change was actually improving the results. This spread turned out to be roughly 4 (for A4), and guided my submissions for A5 as well; I drew the most promising submissions 2-3 times. This generally required one to plan ahead and start early with the assignments, given the set number of gradings allowed per day.

The mistake I made initially, and also in the early stages of A4, was dismissing a change too quickly only on ~2 draws, which can't be a reliable measure if the spread is 4. Next time, I will begin measuring spread first (and start assignments earlier) so I have time to form a meaningful solve average for each change.


## Lesson 2: Inference from local validation

All changes I made generally first ran on 25 local tasks for validation, and based on the result it either went on the leaderboard for grading or the change was reversed. There were a few issues with drawing inference from the local validation:

(a) Improvements locally did not necessarily improve results on the leaderboard; in one instance, an increase in call cap in A4 resulted in up to 19/25 (from ~15) solves locally but only 3/26 (from 6) solves on the board. This instance is shown in the top panel of Fig. 1, shaded in darker grey, together with an inverse move of solves achieved locally versus the leaderboard.

(b) Practically no matter what I tuned, 16 of the 25 local tasks were always solved, leaving only 9 tasks for 'real inference'. I compensated for this in A4 by integrating a harder validation set, which initially was similar to the leaderboard's difficulty (43 % local vs 41 % board solved); later, however, as my pipeline got better, even the hard task set surged to 22/28 solves while the results on the board did not move.

(c) Some tasks failed on the leaderboard with errors that never occurred during local tests, so one could not infer much from the leaderboard in these instances (which was difficult since the leaderboard's logs were thin).

My conclusion was that the local results should be taken with a grain of salt. My mistake was relying on the easy validation set too much, but even later when I realized and swapped it for the harder set, that one saturated eventually as well. For next time, it would be great to more carefully collect a validation set with easy and hard tasks that represent reality, plus have the leaderboard display more detailed logs that show where the pipeline fails.

![Local validation versus leaderboard results, showing limited correlation.](local_vs_board.svg "Figure 1. Solve rate of local (blue) versus leaderboard tasks (orange). Only limited inference could be drawn from any local validation as the board did not necessarily follow the local results (see grey-shaded regions).")


## Lesson 3: Simpler harness wins (for me, anyway)

For A3, I initially built my harness based on a "router" idea: Tasks get distributed based on perceived complexity feeding 3 agents of different strength, with a verdict step, multiple checks, second attempts, a higher-tier retry, and a two-stage submit. This sounded good, but didn't work very well. I scrapped this harness essentially completely, replacing it with an expert-tier only agent, just 3 simple tools (shell, str-replace, submit), and a hard limit on the number of calls. This was the harness that first achieved the 16-solve baseline.

On the way there, I learned lots. One, both in A3 and A4, subtle harness changes rarely resulted in a meaningful increase in solve rate (only 2 of 37 changes had substantial impact in A4). Two, adding a cheaper model before the expert-level model did practically nothing for A3. Three, let the harness write the compaction summary not the model; the model appears more prone to carrying wrong facts (+ costs a tool call). 

The lesson I took was that it pays off to start with the simplest version. Instead of the router, I should've tested each model-type by itself for solves, figure out where the pitfalls are for each, and then, only if there is a clear upside, combine them into a router-type harness. In my case, simply the expert model was enough -- I could've found that out days sooner.


## Lesson 4: Just hammering the top model cannot replace a solid plan

In A3, the first leaderboard graded assignment, I wanted to see whether just using the top model (Fable, ultracode, max effort) without any substantial instruction will place me around the highest rank. I sunk quite some resources into A3: 97% of my agent's replies came from Fable 5.1, API-equivalent cost of around 4,000 USD (class median 349 USD), around 20 USD per prompt (class median 3 USD), and over 40,000 tool calls (the most in the class).

My strategy here was to just let Fable work, with some of my prompt highlights being something like "OK now lock in and get me rank #1!" and "deploy all resources ... no matter the cost". Turns out that's not an efficient way to prompt an AI (course staff classifies 38% of my prompts as "vague").

It was an interesting experiment that I'll remember and that began steering how I interact with Claude. For any of my work, I now ensure that Claude and I are aligned on the overarching goal and on some of the main concerns/problems towards that goal. More often than previously, I now start in Plan mode, to check if I agree with the general approach. I also rarely use Fable anymore; I find that Opus 5.5 on High is plentiful. In summary: AI can't replace your brain (yet).


## Lesson 5: Memory matters

For A4, initially, I had all tasks run in parallel. This meant that the server held 25 separate conversations at once, but its token count simply did not fit on the GPU. What I saw while attempting this, which became only clear by meticulous logging:

- Startup run crashed due to insufficient memory,
- Each model call had large wait times because it was busy,
- GPU memory limited how much model memory could be kept; in the extreme case, the entire conversation is re-read every turn,
- The notes per run (KV cache) were ~95% full all the time; notes were thrown out at 7k tokens/second, practically identical to the rate at which the conversation was re-read

For the most part, this was fixed by limiting concurrent agents away from the 26, which cut net latency by a lot (~35s to ~10s). This also alleviated the issue of overcrowding the server, which can be unable to hold memory and then reduces write speed. For A5, I applied some of these learnings directly: Raising the memory fraction, and imposing an "active set": only agents whose contexts fit a 300k-token cache budget can call the model, the rest wait. The latter resulted in the median gap between turns to drop by 10x (from 50.5 s to 5.0 s), with local solves up 16/25 (from 11/25).


## Lesson 6: Shiny features may lose under load

In A5, I tested three promising engine features: speculative decoding (MTP), a smaller Mamba cache, and CUDA graphs for decoding. Each performed quite well isolated, but either drew too many resources, did not improve outcome significantly, or even dropped net performance compared to baseline when put under agent load:

- MTP: 50% faster than baseline on a single request but cost 56% of the cache; at 12 concurrent requests ran ~0.6x as fast compared to baseline.
- Mamba: 18 % more cache memory, but same number model calls / minute.
- CUDA graphs: 20 % faster per decode step, but consumed higher memory that was limiting at 12 concurrent requests.

Something similar was seen in A4, where the serving benchmark performed much better than the agents. While this was just a quick test, I suppose the broader lesson is to test these features in the environment that they're actually deployed in, and that benchmarks by themselves aren't really meaningful.

![Figure showing MTP performing worse under load.](mtp_under_load.svg "Figure 2. Speculative decoding (MTP) in A5, outperforming the baseline on single requests. As soon as the engine was under load, MTP performed approx. 40% slower than baseline.")


## Lesson 7: Thinking ...

Handling the thinking budget matters. Particularly in A2, I noticed that with a max_tokens call cap enforced, the model spent most of its output limit thinking and returned nothing. I then implemented a conditional limit extension, where max_tokens is raised dynamically if calls come back empty; in A2, it helped solve one task that would otherwise have remained unsolved. I also tried to shorten reasoning, which resulted in 73% fewer output tokens and 43.7 → 18.5 min, but solve rate went down slightly so I did not choose it in the end.

For A4, similarly, I enforced a thinking cap to restrict runaway thinking, and also sent previous reasoning back to the model on every turn as to avoid re-thinking. This reduced the latency per call by about half, from around 10-11 to 6 seconds. Here, I also tried removing the cap then to see the difference; the solve rate decreased, but I only drew once so it is possible this result is just leaderboard noise (see Lesson 1).


## Lesson 8: Let the agent check its work

With limited leaderboard runs, I really wanted to avoid that the agent ships a solution that breaks. In A2, I gave the agent the requirements and the interface for context, in addition to the problem statement. In A4, I had the agent build and check before submission; I also made it write its own tests before any edits.

These adjustments to A4 had a substantial impact. Of the 12 of 25 local tasks the agent solved *sometimes* (call them "flaky" tasks), 53% solved on average. With having the agent build and verify before submission, that jumped up to 67%. If I made it write and run its own tests, solve rate on flaky tasks jumped further to 75-83%. This is a pretty large improvement, I thought.

Based on these findings, I already made changes to how I code with AI: I now always demand "proof" that a change works, by having it execute its own tests and self-diagnosing any issues. While this change in how I interact with coding agents has taken a massive toll on my plan usage limits, I find that the results are much improved.


## Summary: What I would do differently

If I were to start over in this class, here is what I'd do:

- First get a sense of the variance associated with any changes made,
- Take time to build a proper (hard!) validation set that one can draw inference from,
- Try the simplest thing first,
- Pay more attention to hardware memory management and agent thinking budget,
- Define a clear goal for your coding agent, and allow it to check itself routinely,
- Don't rely on the most capable AI model to form a plan for you.

## AI use
The figures were made by Claude from the run logs and leaderboard results on my request; Claude also checked the numbers against the logs. It also helped me aggregate the material I wrote from writeups and videos across all assignments.