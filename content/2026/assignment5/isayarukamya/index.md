---
title: "My AI-gentic Systems Takeaways"
date: 2026-11-26
authors: ["Isaya Charles Rukamya"]
summary: "Running more agents sometimes made everything slower. Generating tokens faster could actually reduce throughput. And switching to a more capable model didn't necessarily improve the results."
tags: ["caching", "observability", "inference", "agent-design", "evaluation"]
draft: false
---

As part of my favorite O(1 semester) endeavor, I spent most of this fall building and optimizing my own AI coding agent: from developing the agentic loop, serving my own LLM on a dedicated GPU to optimizing the entire stack.

<!--more-->

<style>
.post-header { text-align: center; }
.post-header h1::after {
    content: "5 Lessons to Cache in Your Brain";
    display: block;
    margin-top: 10px;
    font-size: 19px;
    font-style: italic;
    font-weight: 400;
}
.post-header .post-meta { justify-content: center; }
</style>

The idea sounds pretty straightforward. You give an LLM access to a codebase, let it investigate a problem, make changes, run tests and hopefully produce a working solution.

However, getting an agent to solve problems reliably turned out to involve much more than just good prompts.

To be clear, I wasn't asking it to solve NP-complete problems. They were mostly regular software engineering tasks, often fixing bugs in existing code without introducing new ones. Yet even that turned out to be surprisingly challenging.

From building the agent itself to running it on my own GPU-backed model server, I encountered more problems than I could fit into this article, even with a generous malloc(). But I'm happy to share a few of my personal be<s>wor</s>sts. Running more agents sometimes made everything slower. Generating tokens faster could actually reduce throughput. And switching to a more capable model didn't necessarily improve the results.

In more depth, here are my five biggest lessons.

## 1. Let AI Agents Be Nondeterministic, Not Your Analysis Pipelines

In most of my work building AI systems, I’ve developed a personal preference for investing a solid amount of time and effort upfront in building a strong telemetry pipeline. My reasons go beyond just saving the time and tokens I’d otherwise spend asking an AI agent to reconstruct telemetry data from raw logs. I also want to avoid adding another layer of nondeterminism to my work, since even asking an AI agent to process those logs is, to some degree, nondeterministic.

For the initial version of my agent, I performed the evaluation runs twice on the exact same agent. The first time, it solved 11/26 tasks, but the second time, it solved just 7. I hadn't changed anything in the code, yet the scores were quite different. Without accounting for this variation, it could be easy to mistake a change in scores for the effect of an optimization.

I had already built a telemetry pipeline earlier, but as my experiments grew more complex, I kept updating it to capture more information across the system. On the agent side, I tracked model calls, tool executions, token usage and task outcomes. From the serving engine, I collected metrics like request latency, cache usage and throughput, along with GPU and host measurements.

I also made sure to preserve the raw logs so I could use analysis scripts to validate the data, generate plots and compare experiments without rerunning them or making additional model calls.

![A pipeline diagram. An AI agent and an LLM serving engine both emit telemetry into a run folder holding a manifest, an agent trace, server metrics and GPU metrics. Offline analysis validates, analyzes and compares runs, leading to performance charts, failure diagnosis, bottleneck identification and configuration comparison. An arrow loops back with the text: change one variable, measure again.](telemetry-pipeline.webp "How structured agent, server, and GPU telemetry, captured during a run and stored as raw records, supports repeatable offline analysis and evidence-based configuration changes.")

My biggest takeaway was that while I couldn't eliminate nondeterminism from the agent itself, I could make the analysis of its behavior deterministic. This became especially useful when I started optimizing the model-serving system.

## 2. “Too Many <s>Cooks</s> Workers Spoil the <s>Broth</s> Cache”

When I began running the agent against multiple tasks, my initial instinct was to maximize parallelism. If I had 26 tasks to solve, why not try giving each its own worker?

Hence, I started with 26 concurrent workers on a single 32 GB GPU.

The results weren't encouraging. The server was spending a surprising amount of time processing prompts, and the median time to first token was about 83 seconds.

A key factor behind this was prefix caching, which allows the model to reuse previously computed parts of a prompt.

When an agent sends a request to the model, the model processes the input tokens through its attention layers, computing keys and values for each token. These are stored in the KV cache on the GPU, so the model doesn't have to recompute them when generating subsequent tokens.

Since agents typically send their conversation history with each new request, much of the prompt remains unchanged. Prefix caching allows the server to reuse the cached keys and values for those unchanged tokens across requests, rather than processing them again.

When it comes to GPUs, memory is limited. With 26 agents maintaining separate, growing conversations, they were competing for the same cache space. Previously cached prefixes were being evicted to make room for new ones, only to be needed again later.

I tried reducing the number of concurrent workers from 26 to 5, and the difference was enormous.

The proportion of prompt tokens served from cache increased from 5.1% to 96.2%, while median time to first token fell from 83.3 seconds to 0.943 seconds.

Instead of constantly recomputing old conversation history, the server could retain and reuse most of it.

![Top: how prefix caching works. Request 2 resends the system instructions, user task and first tool interaction, which are reused from the KV cache, and only the new tool result is computed. Bottom: with 26 parallel workers on one 32 GB GPU the cached prompt-token share is 5.1% and the median time to first token is 83.3 seconds; with 5 workers the cached share is 96.2% and the median time to first token is 0.943 seconds.](prefix-cache.webp "How reducing agent concurrency from 26 to five workers on a single 32 GB GPU raised the cached share of prompt tokens from 5.1% to 96.2% and cut median time to first token from 83.3 s to 0.943 s.")

What I found particularly interesting was that I hadn't made the GPU more powerful or changed the model. I had simply reduced the amount of work competing for its memory.

Of course, five isn't some universally optimal number. The right concurrency depends on the model, workload and available GPU memory. These were also separate local runs, so I wouldn't use them alone to make claims about changes in task-solving accuracy.

From these serving measurements, it’s clearer that more parallelism is only useful when the system can handle it efficiently.

## 3. I Made Token Generation Faster. What Could Possibly Go Wrong?

After optimizing the prefix cache, I looked for other ways to speed up inference.

I found the idea of speculative decoding promising, specifically multi-token prediction (MTP).

Normally, an autoregressive language model generates tokens sequentially. MTP allows a prediction head to propose several upcoming tokens, which the main model can then verify. When those predictions are accepted, the model can make progress through multiple tokens without the same number of sequential decoding steps.

In my experiment, MTP accepted approximately 3.1 out of every 4 proposed tokens on average.

The initial speed measurements looked great. With five concurrent request streams, median inter-token latency dropped from 12.63 milliseconds to 4.56 milliseconds, about a 2.8× improvement.

At first glance, that looked like exactly the kind of optimization I wanted.

But there was a catch.

Enabling MTP came with a memory cost. The available KV-cache capacity dropped from roughly 391,000 to 152,000 tokens, and the server could now handle only four concurrent requests. This meant more requests had to wait, while less cache space was available for reusing previously computed tokens.

That mattered because my agent workload depended heavily on retaining long conversation prefixes.

In a separate experiment using requests with long, shared prompt prefixes, the proportion of prompt tokens reused from cache fell from approximately 68% to 8% when MTP was enabled. Even though token generation was faster, the server was now spending substantially more time reprocessing prompts.

As a result, aggregate generation throughput dropped from 270.6 to 204.4 tokens per second, a decrease of 24.5%.

![Top: standard decoding produces one token per model pass, while MTP speculative decoding drafts four tokens and verifies them once, with about 3.1 of 4 accepted. Bottom: median inter-token latency fell from 12.63 ms to 4.56 ms, KV-cache capacity fell from 391,068 to 152,368 tokens, the cached share of prompt tokens on a warm workload fell from 68.3% to 8.4%, and aggregate throughput fell from 270.6 to 204.4 tokens per second.](mtp-speculative-decoding.webp "How MTP speculative decoding lowered median inter-token latency while shrinking KV-cache capacity and reducing aggregate throughput on a warmed-cache workload in the tested serving configuration.")

The smaller cache, reduced concurrency, and loss of prefix reuse provide a strong explanation for the slowdown, although I didn't isolate each factor independently.

I ended up abandoning that MTP configuration.

This emphasized on being careful about what a benchmark is actually measuring. An improvement in one part of the system doesn't necessarily translate into an improvement in the whole system.

In this case, I could make token generation faster and still make the workload I actually cared about slower.

## 4. Green Tests, Red Flags

Early on, I introduced verification checks to stop the agent from declaring a task complete without showing that its changes worked.

For example, I required the agent to reproduce the original bug, make a fix and demonstrate that the reproduction now passed. Over time, I added stricter checks around test scripts, existing code and task requirements.

These changes improved the agent's workflow, but they exposed the problem that the agent could satisfy its own verification process without actually solving the task.

One example involved a bug in the Python package Pluggy.

The agent produced a patch that passed all 10 tests checking the requested new behavior. The repository's existing test suite also passed. From the agent's perspective, things looked good.

But the hidden evaluation tests showed otherwise.

Although all 10 fail-to-pass tests succeeded, only 10 of 12 preservation tests passed. The patch had fixed the main bug while breaking two cases involving existing behavior.

The task was still unresolved.

This pushed me toward stronger verification, including comparing behavior against the original code and explicitly tracking requirements the agent needed to preserve.

It also changed how I interpreted test results.

A passing test tells you that a particular behavior works under the conditions you've checked. It doesn't automatically mean the implementation is correct in every other case.

For an AI coding agent, the quality of the verification process can be just as important as the quality of the code it generates.

## 5. With Great Power Came Great Inference Costs

My final experiment involved changing the model rather than the agent.

I kept the same agent harness, tools, prompts and task-solving logic, but switched from Qwen3.6-35B-A3B-NVFP4 to Qwen3.8-27B-NVFP4 and made the necessary serving-configuration adjustments.

This was to see whether a model with stronger reported capabilities would improve results without requiring a redesign of the agent.

The outcome was mixed.

On Terminal-Bench 2.0, the newer model solved 8 more tasks than the original, although it took almost an hour longer to finish. On the software engineering benchmark, however, the original model performed better, solving 2 more tasks in considerably less time.

The serving benchmarks helped explain the difference in runtime.

In single-stream generation, the original model produced approximately 176 tokens per second, compared with just 38 tokens per second for the newer one.

That is a substantial difference when an agent makes hundreds of model calls, often generating long responses.

![Two models compared under an unchanged agent harness. On general terminal tasks, V2 solved 8 more tasks in a run about 1.3 times as long. On software engineering tasks, V2 solved 2 fewer in a run about 2.0 times as long. In separate serving tests, V1 generated 176 tokens per second single-stream and 306 across six streams, while V2 generated 38 and 103.](model-comparison.webp "How swapping the model under an unchanged agent harness solved more terminal tasks but fewer software-engineering tasks, with longer evaluation runs and much lower token-generation speed.")

I wouldn't conclude from one evaluation that the newer model is inherently worse at coding. Task order and normal run-to-run variation could affect the scores.

What the experiment did show was that improving model capability doesn't automatically improve the performance of the entire agent.

The newer model helped on one benchmark but didn't improve the other, and its slower inference created a real cost.

Choosing a model means understanding how it performs on your tasks, your hardware and within your available time.

## AI use

As the [course policy](https://cs2680.com/policy.html#ai-policy) requires, I used Claude Code to help write and debug code, run experiments and produce the diagrams in this post from my experiment notes. Claude Code also formatted this post for the course blog.
