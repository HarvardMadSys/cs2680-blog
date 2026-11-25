---
title: "Practical takeaways from constructing performant harnesses"
date: 2026-11-25
authors: ["Advikar Ananthkumar"]
summary: "Takeaways from building and optimizing agent harnesses across four assignments: establish the variance of a baseline first, make one change per experiment, and understand what is preventing the agent from solving tasks before introducing complexity."
tags: ["agent-design", "testing", "evaluation", "model-serving"]
toc: true
draft: false
---

## Context on agentic harnesses

As AI systems are increasingly deployed in more complex environments with access to tools in hopes of solving complex tasks, the structuring of how they are able to do this becomes more important. This specific part between the raw model and how the system orchestrates, uses tools, etc is determined by its harness. In small models, the impact of the harness is more easily seen, as deliberate changes can dramatically change task success. This post is meant to outline some takeaways from experimenting and designing harnesses in optimization for tasks and GPU usage.

## Background

A model can only output tokens/text. A harness turns this into specific actions (running commands, editing files, etc), feeds results back, and decides when and how to stop. For evaluation, we use a hidden test suite that grades the final state. A harness designed to solve tasks must also optimize around the constraints of fixed time, money, compute, and parallelism. A harness can be optimized in many ways across many axes. These include prompt + tools, the loop control, the context, the verification logic, the model use, scheduling, the serving engine, measurement, etc.

The experimentation I conducted was in a series of assignments, taking me from building a harness to optimizing it when served. The first (A2) was constructing a command line agent loop that solves tasks on a real repository issue. The model was fixed as a small open model, Qwen 35B. This was also purely for task hill climbing, and there was no cost or time penalty. The specific challenges to then work on were getting a task solved with guards against the agent breaking the repo, making sure it was done, with reasonable turn and time limits.

After this (A3), we introduced the constraints of cost and time. Specifically, given 26 hidden tasks and access to two models through an API (a standard model and a more expensive expert model), the goal was to optimize for tasks, time, and cost. The challenge driving the experimentation here was maximizing task success relative to the cost of getting there. This introduced more decisions around when to use a stronger model, when to retry a task, how much context to maintain, etc.

We then (A4) moved away from using an API to serving the model ourselves on a single GPU (RTX PRO 4500, 32 GB). Now, the bottlenecks were different: Instead of optimizing for the cost of an API call, we were optimizing around the allocation of compute across the tasks. This means that the optimization of the serving engine, concurrency, and amount of thinking becomes more important.

Finally (A5) I was tasked with constructing a general harness that performs well across two benchmarks. In addition to the previous 26 tasks, we evaluated on Terminal-Bench 2.0. The agent also no longer had access to the grading tests during run time, so it had to develop its own idea of when a task was solved and correct.

---

## Lessons

### Variance

I think one of the bigger mistakes I made early on was treating results from experiments and the performance of a harness as a deterministic thing. I'd make a change and based on the results determine if the change was good or bad. This is particularly tempting when every grading takes several hours and you have a limited number of gradings. In A5, I submitted the exact same harness five times and got 27/32/37/33/28 tasks solved. This is a difference of 10 tasks with no changes to the harness. I saw similar variance in A4, where six submissions of the same harness went from 7 to 11 tasks out of 26. There are a lot of sources of variance -- Outside of just the stochasticity of the model itself, things like the order of tasks, the length of other requests served on the GPU, when a task hits its time limit, etc. all impact the final result. In A3 there were a lot of changes that I threw away based on a single grading despite observing the same harness get anywhere from 7 to 14 tasks solved. It's possible that some of the changes I changed back were actually helpful. I think establishing the variance of a baseline before doing any significant experimentation is super important.

### Actual hillclimbing

A similar issue I ran into was how to structure the experimentation when the feedback loop is extremely slow. For harness benchmarking, the grading and iteration process is not instantaneous. In A3 I had 20+ versions of my harness and made 62 submissions. Many of these versions were built on top of one another, with many changes between each submission. When performance regressed, it was increasingly difficult to isolate what was causing the regression. In A5 I took a much more deliberate approach. I fixed a baseline and made just one change per experiment. Before running the experiment I tried to log why I thought the change would work, what things I expected to change, and what would be enough evidence for me to add it into the harness. For example, one experiment involved capping thinking at 8192 tokens. The 2 runs with this change solved 11/26 tasks each, which was higher than all five runs of the baseline. There were also experiments where the predetermined criteria stopped me from adding changes that initially looked good. One of these was reducing the number of runaway model calls from 30 to 27, but the expectation was that it would bring this number down to 22.

Something I learned here was the importance of defining what you are actually testing. I feel like I had decent intuition that a change should work, but had not materialized that into something that could be measured. Doing this beforehand also helps prevent retroactively justifying changes based on whatever happened to improve.

### Local testing

A significant portion of my iteration process went into making a local evaluation infrastructure. The idea was that if I could locally set up the grading environment, I could do a lot more experimentation before submitting. There were two problems with this: The first was replicating the actual environment. I was running a lot of my local tests on a Mac, emulating x86 environments. The first local eval in A4 said 0/25 tasks solved because the grading script was incompatible with the version of bash on macOS. I ran into a similar issue in A3 with the absence of a GNU timeout command. The second more interesting problem was that I was basically optimizing on a different set of tasks. In A3 I made proxy tasks to eval the relative performance of different harnesses. These eventually saturated at 10/10 and 12/12 tasks solved. In A4, a harness that got 14/25 locally got 7/26 on the actual grading.

I still think local evaluation is extremely valuable, but I would distinguish between testing if a specific component of the harness works and testing if the harness is performant. The latter requires a lot more thought about how representative your tasks and environment actually are.

### Thinking

One of the more interesting axes of optimization was how much the model should "think". My initial intuition was that because I'm working with a smaller model, reasoning through the problem should be very important for task success. The issue is that when compute is constrained, thinking tokens directly compete with the number of turns an agent can take.

In A4 I experimented with different thinking configurations on a subset of 10 tasks. With thinking disabled, the agent solved 4/10 tasks. With thinking restricted to read-only operations, it solved 6/10, and with thinking fully enabled it solved 8/10. At the same time, I saw four individual turns with over 8,000 thinking tokens, with one request taking 754 seconds. In an env where 26 tasks share a GPU, this is a significant amount of compute allocated to one decision in one task. In A5, capping the amount of thinking allowed the agent to take 2,245 and 2,095 turns across two runs, instead of around 1,795 to 2,000 turns in baseline runs.

The interesting question isn't if thinking helps the model, but what the marginal value of additional thinking is relative to other actions. For an agent with access to tools, it might be more valuable to do a command and get more info about the environment than to spend thousands of additional tokens reasoning about the information it already has.

### Model Strength

In A3 a lot of my initial experimentation was about figuring out when to escalate to the expert model. The premise was that the standard model could solve most of the easier tasks and the expert model could be used to solve the more difficult tasks or recover from failures of the standard model. This ended up being a lot less effective than I expected. A set of expert escalations cost ~$3.50 for at most 1 extra task solved. In another experiment, 6 escalations rescued 0 tasks. Using the expert model from the beginning also only got 4/10 tasks solved in one experiment which was the same number as the standard model on a different subset of tasks.

Another harness was able to solve 17/26 tasks using only the standard model which was better than anything I had got while using both models.

Looking at the execution traces, tasks that went past 100 turns were almost always failures. Escalating after this point meant that I was giving a stronger model a super long context containing the failed attempts of another model. It's not clear that this is a useful starting point for the stronger model.

Before using a more capable model it's worth understanding if the failures you see are actually a result of the capabilities of the model. A lot of the failures I saw were related to the way the harness was structured, how context was maintained, and how the agent interacted with the environment, which can all persist regardless of the model being used.

### Verification

One of the first things I tried in A2 was a verification step. When the agent said that it was done, the harness would run syntax checks and repo tests before letting the agent terminate. This would hopefully introduce some signal outside of the model's own assessment of whether it had solved the task. I experimented with extending to A3 by automatically rejecting the first "done". This forced the agent to spend more time reviewing the work, but ended up adding around 5-10 min per task. The issue with this was that the additional work wasn't motivated by any new info about the correctness of the solution.

In A4, I experimented with a requirements gate that eval'd if the agent had actually addressed the requirements of the task. In one run, this gate rejected 3 of the 10 tasks, and two of them became solves. With thinking disabled, the gate approved all four of the tasks presented to it.

I think the effectiveness of a verification step is dependent on if it provides information that the agent didn't already have. Asking the model to look over its own work again can be useful, but is fundamentally different from giving it the output of a failed test or some concrete evidence that a requirement isn't met.

This became important in A5 where we no longer had access to the hidden tests during runtime. A big part of constructing a performant harness in this setting is making useful signal for the agent to determine what it needs to fix and when it should stop.

### Good infrastructure

A large amount of the time I lost across the assignments was not related to the actual performance of my harness. In A5 my laptop went to sleep while on battery for 21 hours and my login expired, which resulted in me not being able to use either of my last two gradings. In A4, a thermal sleep invalidated an entire timing experiment. In A3, cancelling a stuck grading lost a run that had already solved 10 of the 18 tasks it had evaluated.

These issues are particularly bad when the feedback loop for an experiment is hours long. Losing a run means losing the information that would have informed your next set of experiments.

In retrospect, I would have spent a lot more time building reliable infra for launching, monitoring, and logging experiments. It's easy to justify spending time implementing an optimization to the harness, but making sure that the experiment actually runs to completion may have much higher EV.

### Carried-over settings

One of the biggest mistakes I made when going from A3 to A4 was carrying over configurations I had tuned for the paid API without reconsidering them in the context of serving the model myself. Specifically, I had a 15 minute time limit per attempt and a limit of 8 concurrent requests. On my first grading of A4, 7 of the 26 tasks didn't produce a patch. Looking through the traces, I found that individual calls were spending ~30 seconds waiting in the concurrency queue of my own harness to generate around 100 output tokens. I also found a config bug that meant the logic I had implemented to control the amount of thinking the model does was never being executed. I was allocating time to tasks without accounting for how much compute they were actually getting in that time. A lot of the optimizations I made in A3 were based on assumptions about the latency and throughput of the API that no longer held in A4. I think when changing the environment in which a harness is being run, it's important to revisit parameters before making more involved changes to the agent itself.

### Serving + Harness

Another aspect of serving the model ourselves was seeing how decisions made at the harness level impacted the performance of the serving engine. When experimenting with batching, I observed decode throughputs of 163, 202, 311, and 323 tokens per second, with throughput saturating at a batch size of 4. Increasing the number of concurrent requests beyond this point had diminishing returns in terms of added up decode throughput. Another example of this was prefix caching. I saw a cache hit rate of 0.83, but some of the context management logic I had implemented rewrote earlier parts of the convo in place, stopping the serving engine from reusing the affected cached prefixes. I think this is an interesting example of how something that may seem like a reasonable optimization in the context of the harness can actually be bad to the performance of the system as a whole.

---

## Closing

Going into this (A2-A5), I thought of a harness as the logic surrounding a model that lets it interact with an environment. While this is true, I think I underestimated how much of the performance of an agent is determined by decisions outside of the model itself.

If I were to make another harness from scratch, I would spend a lot more time establishing a reliable eval setup, understanding the variance of a baseline, figuring out where time and compute are being spent, and understanding the failure modes of the agent before introducing complexity.

A lot of my early experimentation was motivated by intuitions about what would make an agent better at solving tasks. As I progressed through the assignments, I found myself spending more time understanding what was preventing the agent from solving tasks in the first place. The distinction is important and changed a lot about how I approached optimization.

---

## AI use

As the [course policy](https://cs2680.com/policy.html#ai-policy) requires: I used Claude Code throughout these assignments to write harness code, run and log experiments, and analyze results.
