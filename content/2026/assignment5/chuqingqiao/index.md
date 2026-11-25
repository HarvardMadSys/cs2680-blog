---
title: "Design for the constraint: lessons from building, racing and serving a coding agent"
date: 2026-11-24
authors: ["Chuqing Qiao"]
summary: "Four assignments building, racing and self-hosting a coding agent taught me to measure noise first, talk to the model the way it was trained, size concurrency to the cache, and above all to design for the constraint I was judged on instead of for \"better\"."
tags: ["agent-design", "context-management", "llm-serving", "evaluation"]
toc: true
draft: false
---

This semester we were tasked with building a coding agent multiple times. In Assignment 2 it was a bare tool loop that
solved 4 of 10 tasks. By Assignment 5 it was a general terminal agent, running on a model I served
myself on one GPU, that solved 32 of 89 Terminal-Bench tasks in under two hours. These are the
tips, tricks and gotchas I picked up along the way, in the order I learned them. If I could keep
only one, it would be this: design for the constraint you're judged on, not for "better".

<!--more-->

## Overview

The four assignments built on each other, so I'll go through them in order. Each one handed me
another layer of the stack and moved the bottleneck somewhere new. In Assignment 2 I
only built the loop, and the hard part was getting the agent to understand the task, so those tips
are about what the model sees and how its work gets checked. Assignment 3 added three models with
real prices and a class leaderboard, and the hard part became money; the tips there are about
noise, spending, and playing to the scoring rule. In Assignment 4 I served the model myself under
the same agent, and the bottleneck moved into my server's cache, which brings tips on inherited
settings, caches, timeouts, measuring end to end, and the scoring rule again. Assignment 5 put the whole stack in my hands,
with one general agent for two benchmarks, and what mattered was the run as a whole. Its tips are
about the agent's context and setting limits from data.

One thread runs through the last three: each was a constrained optimization problem, solving as
many tasks as possible within a time limit or a dollar budget, ranked by a specific rule. Keep this in mind - I'll
keep coming back to it, and hopefully by the end of this blog you'll see the importance of this
specific optimization setup the same way I do.

![A grid with one column per assignment (2 to 5) and rows for tasks, agent, model, serving and scoring. Cells new in each assignment are blue; the Assignment 4 agent and the Assignment 5 model and server are carried over. The bottleneck row reads: reading the task, money, the server's cache, the whole run. Best results: 7/10 and 6/10; 17/26 at $0.34 per solve; 9/26 in 92 minutes; 32/89 in 105 minutes and 6/26 in 41 minutes.](fig-stack.svg "Figure 1. What each assignment added (blue) and carried over (dashed), the bottleneck I ended up fighting, and my best result.")

## Assignment 2: baby steps 

Assignment 2 was madsLoop, a harness that runs Qwen3.6-35B-A3B (through the course API) on 10
SWE-bench Pro tasks. The handout gave us a deliberately minimal starting design, four tools (bash,
read a file, edit a file, done) and a loop that ends when the model stops calling tools, and told
us not to trust it. That design solved 4 of the 10 tasks. My final version solved 7 (Figure 2),
and the biggest jumps came from small, basic steps rather than a smarter loop. Let's look at the
problems I ran into and what I took away from them.

![A grid of 10 tasks against 10 runs, from v1 to the second run of v2.6, with resolved cells filled. Solved per run: 4, 2, 6, 4 (a run cut short by the API budget), 6, 5, 7, 6, 7, 6. v2.5 and v2.6 were each run twice with no code change, and each time a different task failed in the second run. Three tasks marked as argued unsolvable were never resolved, except teleport by v1.](fig-a2-grid.svg "Figure 2. Assignment 2: which of the 10 tasks each run resolved. The same code (v2.5, v2.6) scored 7 and then 6, failing a different task each time.")

### The agent couldn't see what it was graded on

My first rewrite added sturdier tools, nudges when the model replied without calling a tool, and
context compaction. It solved 2 of 10, worse than the minimal version. Like the minimal version, it
showed the agent only the issue's problem statement, but the exact names the tests looked for were
only in the task's Requirements and Interface sections. Once the next version passed the agent the
full text, it solved 6.

### The agent believed its own checks

Next I tried to make the agent check its own work, with mixed results. On one task it used a field
path from memory instead of the one in the spec, then wrote a reproduction script with the same
wrong path, so its own check passed. A second call to the same model, reviewing each diff against
the spec, said "no issues" on three patches, two of them wrong. Prompt rules were hit or miss: on
one run the agent simply ignored a rule about which exports a file needs. Moving that rule out of
the prompt and into code, a check that refuses `done` until the exports are right, gave me a
version that solved 7 and then 6.

Figure 2 also shows something I didn't take seriously at the time: v2.5 and v2.6 were each run
twice with no code change, and each scored 7 and then 6, losing a different task on the second
run. It turned out to be one of the most important traits of agent development, and it shows up
again in every assignment after this one.

<div class="tips-box" style="background: var(--surface); border-left: 3px solid var(--crimson); border-radius: 4px; padding: 0.25rem 1.25rem; margin: 1.5rem 0;">

### Tips from Assignment 2

**Give the model everything the grader checks.** Before tuning prompts or tools, check that the
agent can see everything it will be graded on. A lot of what looks like weak reasoning is missing
context.

**Don't let the model grade its own homework.** Move every rule you can out of the prompt and into
code that runs outside the model (a compiler, a type checker, a script). Treat a prompt rule as a
suggestion, and don't count on the model reviewing its own work.

</div>

## Assignment 3: \$\$\$

Assignment 3 turned the harness into a competition: 26 hidden SWE-bench Pro tasks on a class
leaderboard, three models at very different prices (the expensive one cost 25 to 36 times more per
token than the mid-tier one), and a ranking on three things at once: tasks solved, cost per solve
and time per solve. My best run solved 17 of 26 at <span>$0.34</span> and 650 seconds per solve.
Getting there was mostly a fight with noise, money and the ranking itself (Figure 3).

![A dot plot of tasks solved for each of 31 full leaderboard submissions, numbered 2 to 33, grouped by agent version (M1 to M3, M4, M5, the M6 family, M7, M6c++). Scores range from 8 to 17 around a baseline line at 16. Submissions 28, 29 and 32, the same zip, scored 17, 15 and 13. Submissions 9 and 12, with the same $3 budget pool, scored 14 and 10. A lower panel of bars shows dollars spent per run: about $9 for submissions 4 to 6, then mostly $4 to $6.](fig-a3-leaderboard.svg "Figure 3. Assignment 3: all 31 of my full 26-task leaderboard runs, in order (two partial early runs left out). Below: what each run spent.")

### My improvements were smaller than the noise

With a leaderboard to climb, I kept changing things and resubmitting, and most of what I measured
was noise. The same agent varied by about two solves from run to run: one zip scored 17, 15 and 13
(blue), and two submissions with the same settings scored 14 and 10 (orange). Most of
my tweaks landed inside that band. My local tasks didn't help much either. The first ones were too
easy to tell me anything (solved 16 of 18), a harder batch still didn't reproduce my leaderboard
failures, and even on a bank of 18 hard tasks the noise between runs was bigger than most of the
effects I tested.

Part of the problem was the number itself. A score like 17/26 squeezes every task down to solved
or not solved, but each task really has some probability of being solved, not a yes or no. Across
my 31 full runs, only two tasks were solved every time and only three never were;
every other task was solved in some runs and not in others. A total can't tell you which tasks
moved, where and why a task failed (a wrong patch, no patch at all, tests that never ran), or how much of
a difference is just a coin flip. The per-task results told me far more than the headline number.

### The expensive model ate the budget

My first plan let the mid-tier model do the work and the expensive one take over after a failed
grading. The expensive model ended up as about 75% of the bill, and about 7 of 10 of its takeovers
went to tasks that failed anyway. A cap per task still left a run near <span>$9</span>; pacing its
budget across the whole run brought that to about <span>$5</span> for one fewer solve. In my best
submission it only wrote the plan, and that was where it earned its price: its plans passed on the
first grading 46% of the time, against 28% for the mid-tier model's own.

### I optimized for "better" instead of for the ranking

The ranking was a Pareto front: you're in the top layer if nobody beats you on all three metrics
at once. My best run was balanced, and that was the problem. It landed in the second layer, 23rd of
62, because other runs solved as many tasks more cheaply and faster. A run that is the best at any
single metric can't be beaten on all three, so it lands in the top layer automatically. My write-up
from then admits it: it would have been better "to minmax-optimize for a single metric", and I
noticed too late. My final attempt, a fast variant that graded each task only once, became my
fastest run at 522 seconds per solve, but it solved only 13 and never reached the top layer.
Halfway to an extreme is just another point in the middle.

This was the first time the scoring rule, more than the agent, decided my result, and I took that
seriously in the next two assignments.

<div class="tips-box" style="background: var(--surface); border-left: 3px solid var(--crimson); border-radius: 4px; padding: 0.25rem 1.25rem; margin: 1.5rem 0;">

### Tips from Assignment 3

**Measure your noise, and look past the headline number.** Run the same configuration a few times
before changing anything; a change smaller than the spread between identical runs is invisible. A
solved count turns each task's chance of success into a yes or no, and hides which tasks moved, why
they failed and how much was luck, so compare task by task. And make sure your dev set fails the way
the real thing does.

**Spend the expensive resource where the wins are.** Find out where your successes actually come
from, then stop paying for the hopeless cases. My expensive model was worth more planning at the
start than rescuing at the end.

**Design for the scoring rule, not for "better".** When you're judged on several things at once,
you don't need to be good at all of them. Being extremely good at one is often worth more than
being a jack of all trades, as long as you commit to it early.

</div>

## Assignment 4: theory is theory, practice is practice

Assignment 4 took away the course API. I served the model myself, Qwen3.6-35B-A3B (NVFP4) on one
32 GB RTX PRO 4500 with SGLang, pointed my Assignment 3 agent at it, and the task was to make the 
whole run faster. The leaderboard had 26 new hidden tasks and a baseline of at least 7 solved within 100
minutes. My best run solved 9 in about 92 minutes. Surprisingly little of that came from making the
GPU itself faster, and most of what I learned fits the title: things that should have worked on
paper, like running more tasks in parallel and decoding faster, made the real run worse.

### My old settings didn't fit the new setup

My first full run solved 2 of 25 local tasks, and the agent wasn't the problem. It still carried
its Assignment 3 run budget of <span>$7</span>, priced at the course API's rates, and on my own
server it dutifully stopped every task after 18.5 minutes. Turning that off took the next run to
10 of 25. A quieter one cost more: a setting I had read as 60 minutes was actually 60 seconds, so
every task got exactly one grading and no retries, in every run before I finally tested a fix.

### More tasks in parallel made everything slower

In that 10-of-25 run the GPU was 93% busy, yet model calls were slow, because the server was recomputing
prompts it had already seen. With all 25 tasks open, only 6 to 12% of prompt tokens came from the
prefix cache for most of the run (Figure 4). The model is a hybrid: most of its layers keep a
recurrent state instead of a normal KV cache, and the server can only reuse a cached prefix if that
state is still around. Twenty-five agents kept evicting each other's. Opening only 8 tasks at a
time kept the hit rate around 95%, cut the median model call from 35.5 to 4.3 seconds, and took
the run from 10 to 19 solved. Opening 10 instead of 8 finished no more tasks in the first half hour.

![Two lines over about 77 minutes showing the share of prompt tokens served from the prefix cache. With 8 tasks open the share stays around 90 to 97 percent after the first few minutes. With 25 tasks open it falls to 6 to 12 percent by minute 4 and stays there until minute 58, when about 10 tasks are still open, then jumps to about 97 percent.](fig-a4-cache.svg "Figure 4. Assignment 4: share of prompt tokens served from the prefix cache, from the server's metrics every 10 s. With 25 tasks open the cache barely worked until most tasks had finished.")

### My timeouts killed slow calls, not stuck ones

In Assignment 3 the course API sometimes hung, and a 90-second silence limit was the fix. On my own
server, the 90-second timeout I carried over did the opposite. Calls weren't stuck, they were
queued, and every abort threw away the work the server had already done: in the 25-task run,
aborted calls accounted for 38% of all decoded tokens. Raising the timeout to 600 seconds took
aborts to zero and cut the run from 77 to 73 minutes.

### Faster decoding made the run slower

The obvious way to speed up serving was speculative decoding, and on its own it worked:
decoding got 1.5x faster. But the server sized its
KV cache while the draft layer still held an extra copy of its weights, so the cache shrank from
about 391,000 tokens to 72,000. Even after I tuned it back up to 264,000, the full run was slower
and solved fewer: 16 of 25 in 86.6 minutes, against 19 in 73.3 without it, with the cache hit
rate down from 94% to 71%. It was one of three predictions about speed I got wrong in this
assignment.

### Playing to the scoring rule, on purpose

After Assignment 3, I read the scoring rule before anything else, and this time I designed for it
explicitly. Leaderboard points were 61 minus your rank, but the baseline alone was worth 40
of the 60 points, and only a top-20 rank earned anything more. So the goal wasn't a "better" agent;
it was 7 solves in under 100 minutes, reliably. My first submission solved 7 but took 139 minutes,
so it missed. I added a run limit that stopped opening tasks after 81 minutes and wrapped up by 86,
plus a hard stop for anything still running. That finished in 92 minutes, and the same zip scored
5 and then 9 of 26, which met the baseline. Replaying the leaderboard's task times told me which
constraint was binding: even with every task twice as fast, I'd get only 5 to 7 solves, so the gap
was the solve rate, not speed. The leaderboard tasks were also far harder than my local ones: the
same configuration solved 76% locally and 27% there.

<div class="tips-box" style="background: var(--surface); border-left: 3px solid var(--crimson); border-radius: 4px; padding: 0.25rem 1.25rem; margin: 1.5rem 0;">

### Tips from Assignment 4

**Re-derive every inherited setting.** When you move a system somewhere new, list every budget,
limit and timeout and work each one out again. Defaults carry the assumptions of the old setup, and
a unit in a name only helps if you read it.

**Size concurrency to the cache, not the GPU.** Agents resend long, growing prompts. Once requests
in flight start evicting each other's cache, more parallelism means less throughput.

**Time out on no progress, not on duration.** A hung call and a slow call need different handling.
On your own server, an aborted call throws away work that was already done.

**Benchmark end to end.** A faster component can make the whole system slower. Micro-benchmarks
miss memory, cache and queueing trade-offs; only a full run settles it.

**Read the scoring rule, then find the binding constraint.** Work out what actually earns points
(here, a baseline worth two-thirds of the score) and which limit decides whether you get them.
Design for that, and stop optimizing what doesn't bind.

</div>

## Assignment 5: know when to quit

Assignment 5 asked for one general agent that could handle both Terminal-Bench 2.0 (89 varied
terminal tasks, each with its own time limit) and Assignment 4's 26 repository tasks, on the same
GPU, with the agent, the engine and even the model open to change. I threw away the
SWE-specific agent and wrote a general terminal agent. Following the tips I've summarized above, I read the scoring
rule first: the "fast" baseline, at least 20 Terminal-Bench solves with the whole run ending within
two hours, was worth the full leaderboard score, so every limit in the agent was set against that
two-hour clock. My submission solved 32 of 89 in 105 minutes, which met it. Most of what made that
work was knowing when to stop thinking or give up on a task, and how to talk to the model.

### My agent didn't talk to the model the way it was trained

The model thinks before it acts, and each turn the agent decides how much of that reasoning to send
back with the history. Between Assignments 4 and 5 I finally read what the model expects. Qwen3.6's
[model card](https://huggingface.co/Qwen/Qwen3.6-35B-A3B) says it "has been additionally trained to preserve and leverage thinking traces from
historical messages", behind a `preserve_thinking` option, and calls this "particularly beneficial
for agent scenarios". My Assignment 4 agent sent no reasoning back at all, so the model never saw
the traces it was trained to build on. And by default the chat template keeps reasoning only for
turns since the last user message, so every nudge my harness sent as a user message quietly threw
away all the reasoning before it. In effect, the live prompts had drifted away from what the model
saw in training.

For Assignment 5 I matched the training setup: send every turn's reasoning back with
`preserve_thinking` on, so the history only grows at its end. I also tested two alternatives on 12
tasks (Figure 5). Keeping only the latest turn's reasoning changes the middle of the history every
step, so the server recomputed the last few turns on every call: 2.9 times the uncached tokens, and
1.67 hours of model time against 0.91. Sending none kept the cache, but the model wrote about 50%
more per call, probably redoing thinking it had thrown away. The solves (9, 8 and 9 of 12) were
within noise, so model time, not the solve count, is what confirmed the choice.

![Two bar charts comparing three ways of sending the model's reasoning back, on the same 12 tasks. Uncached prompt tokens per call: recent turns append-only 926, latest turn only 2,691, none 819. Model time: 0.91 hours, 1.67 hours and 1.32 hours. Tasks solved: 9, 8 and 9 of 12. The append-only policy, which the submitted agent used, is highlighted.](fig-a5-reasoning.svg "Figure 5. Assignment 5: three ways of sending the model's reasoning back, on the same 12 Terminal-Bench tasks. The solve counts are within noise; the tokens and model time are not.")

### Most tasks were solved early or not at all

In my first full run I grouped tasks by how long they had been open (Figure 6). Tasks that
finished within 2 minutes were solved 9 times out of 11; past 10 minutes, only 4 of 33 were; and
none of the 17 tasks open longer than 25 minutes was solved. No task was solved after 1,385
seconds. So the next version gives every task a 1,500-second budget, which freed about 10,000
worker-seconds for tasks that could still be won. Along with a few other changes, the full run went
from 30 of 89 in 115 minutes to 32 in 103.

![Grouped bars of the share of tasks solved by how long each task was open, for the first full run (v1) and the second (v2). v1: 0 to 2 minutes 9 of 11, 2 to 5 minutes 9 of 14, 5 to 10 minutes 8 of 14, 10 to 15 minutes 3 of 25, 15 to 25 minutes 1 of 8, over 25 minutes 0 of 17. v2: 10 of 12, 5 of 11, 9 of 17, 4 of 25, 4 of 24, and no tasks over 25 minutes because of its 1,500-second budget.](fig-a5-time-open.svg "Figure 6. Assignment 5: share of tasks solved by how long they stayed open. In my first full run, no task open longer than 25 minutes was solved, so the next version stops each task at 1,500 s.")

### Capping the thinking backfired

The same run showed that 1.2% of model calls, the replies over 8,192 tokens, took 24% of model
time, so a cap on thinking looked like free time. My next draft capped it at 8,192 tokens, and on
a test run one task took 91 steps instead of 11. The full-run numbers also showed that 5 of my 30
solves had started with a single 9.5k to 14.6k-token planning reply. So I kept the 16k cap and
limited each reply to 45% of the task's remaining time instead: long thinking is allowed early and
squeezed late.

### The agent didn't check what it left behind

Terminal-Bench grades the state the agent leaves behind, and some failures were about that state,
not the solution. One agent "put sqlite3 on the PATH" by editing `~/.bashrc`, but the tests run in
a fresh, non-interactive shell. Another left a `make -j16` running in a one-CPU container, and the
tests' own package install crawled for 12 minutes. Others were the same precision misses as in
Assignment 2: a field named `val` where the tests expected `value`, or a 1.19× speedup where 1.2×
was required.

<div class="tips-box" style="background: var(--surface); border-left: 3px solid var(--crimson); border-radius: 4px; padding: 0.25rem 1.25rem; margin: 1.5rem 0;">

### Tips from Assignment 5

**Talk to the model the way it was trained.** Read the model card and the chat template, and send
the history in the format the model learned on; anything else is a quiet form of drift. For
Qwen3.6 that also meant an append-only history, which is the cheapest one for the prefix cache.

**Set every limit from data.** Look at where your successes actually happen before choosing a
step, time or token limit, and expect to be wrong in both directions: in Assignment 2, *raising*
the step limit from 50 to 150 is what let my agent solve one of the tasks I built to test it.

**Budget by the clock you're judged on.** Cap work by the time left, not by a fixed count. Long
thinking is worth it early and wasteful late.

**Check the final state the way the grader will.** A fresh shell, no leftover processes, and the
exact names and thresholds the task asked for.

</div>

## Conclusion

Looking back, two things showed up in every assignment.

The first is noise (Figure 7). The same configuration, run more than once, never gave the same
score: 7 and then 6 in Assignment 2; 17, 15 and 13 in Assignment 3; 5 and then 9 in Assignment 4.
In Assignment 5 the total barely moved (32, 34 and 32 of 89), but about 16 tasks changed between
two runs. I saw it in Assignment 2 and only took it seriously in Assignment 3. Now I would measure
it before anything else.

![A dot plot of the share of tasks solved when the same configuration was run more than once. Assignment 2 v2.5: 7 and 6 of 10. Assignment 2 v2.6: 7 and 6 of 10. Assignment 3, one zip: 17, 15 and 13 of 26. Assignment 4, one zip: 5 and 9 of 26. Assignment 5, v2 on Terminal-Bench: 32, 34 and 32 of 89, with about 16 tasks flipping between two runs.](fig-noise.svg "Figure 7. The same configuration, run more than once, in every assignment. Totals moved by up to 4 tasks; in Assignment 5 the total barely moved, but about 16 tasks changed between two runs.")

The second is the lesson I'd keep if I could keep only one. From Assignment 3 on, every assignment
was a constrained optimization problem: as many solves as possible within a time limit or a dollar
budget, ranked by a specific rule. When I tried to simply make the agent "better", most of my
changes disappeared into the noise. When I designed for the rule, by pacing the budget in
Assignment 3, adding the 100-minute run limit in Assignment 4 and setting every limit against the
two-hour clock in Assignment 5, it paid off. And when the ranking was a Pareto front, the right move
was to be extremely good at one thing rather than decent at everything, and to commit to it early.

Yes, this is Goodhart's law at work: I was optimizing the measure. But I think it transfers. Real
projects have deadlines, budgets, and people who care about some things far more than others.
Being explicit about what actually matters to you and your users, and building toward that instead
of toward "better" in general, is a habit worth keeping well beyond a class leaderboard. You don't
need to be the best, or even good, at everything. Being extremely good at the one thing that matters
is often worth more than being a jack of all trades.

## AI use

I used Claude Code throughout Assignments 2-5, as the course requires, to write and run the agent,
serving and analysis code and to keep the lab notebooks the numbers here come from. For this post,
Claude Code (Claude Opus 5.5) gathered the numbers from my notebooks, logs and write-ups and checked
them against the original files, generated the figures from my data, and helped me with formatting, 
rephrasing, and grammar checking. I chose the lessons, the structure and the section themes, and edited every section.
