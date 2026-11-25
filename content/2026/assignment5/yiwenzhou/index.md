---
title: "Lessons from Building and Optimizing AI Agents"
date: 2026-11-24
authors: ["Yiwen Zhou"]
summary: "Seven lessons from building and optimizing AI agents across four assignments, covering experimental methods, working with coding agents, agent design, and system-level trade-offs."
tags: ["agent-design", "system-optimization", "experimentation", "caching", "context-management"]
draft: false
# cover: "cover.webp"   # optional: a figure to show on the listing
---

Building better AI agents requires careful experimentation, clear optimization objectives, and an understanding of how different system components interact. Simple changes guided by measurements can often be more effective than adding complexity.

<!--more-->

## 1. Measure First, Optimize Second

Before making any changes, it is important to profile the system and understand where the bottleneck is. In A4, 94% of agent time was spent waiting for the model. Reducing concurrency from 25 to 10 increased the cache hit rate from 19% to 94% and reduced response latency from 55 seconds to 4.2 seconds.

Experimental results can also be noisy. In A5, two runs with identical configurations solved 30 and 33 tasks, with the second run gaining nine tasks but losing six. Ideally, experiments should change one variable at a time and be repeated. When full runs are expensive, smaller experiments, per-task comparisons, and replay simulations can help. The important thing is to recognize uncertainty rather than draw conclusions from a single run.

## 2. Working with Claude Code

My approach to working with Claude Code changed throughout the assignments. In A2, I closely supervised Claude Code. In A3, Claude worked largely independently because experiments were relatively cheap and the evaluation criteria were clear. In A4 and A5, however, experiments became more expensive, and there were many more optimization directions to explore. I found Claude less effective when working independently on these two assignments.

Claude was good at implementing ideas, building measurement tools, and documenting results. However, it sometimes struggled to identify promising optimizations that could actually improve performance. In A4 and A5, I found Claude more effective when I provided a specific direction rather than letting it explore independently.

## 3. What Makes an Agent Better?

What makes an agent better depends on its use case and evaluation criteria. Beyond accuracy, factors such as execution time and cost also matter. Throughout the assignments, I learned that improving one of these metrics often comes at the expense of another.

In A3, using a stronger model or combining cheaper and stronger models offered different trade-offs. I pursued an extremely low-cost solution using only the standard model, sacrificing some accuracy. Similarly, in A5, my main improvement was reducing execution time at the cost of some accuracy.

## 4. Simpler Designs Often Work Better

Many additional mechanisms I experimented with did not provide consistent improvements. In A3, I experimented with verification and feedback cycles, but found that disabling them improved overall performance. In A4, adjusting a single sampling parameter was more effective than implementing a custom mechanism to control reasoning length.

In A5, one of the most effective changes in the high-concurrency configuration was simply turning off thinking, while additional more complex mechanisms did not demonstrate reliable improvements. Given the noise in experimental results, this does not prove that simpler designs are always better, but the additional complexity was often not justified by the observed benefits.

## 5. System Optimization Requires Balancing Trade-offs

Concurrency, context length, cache capacity, reasoning length, and task time limits all interact. Increasing concurrency allows more tasks to run simultaneously but also increases memory pressure. More aggressive context compaction can support higher concurrency and reduce execution time, potentially at the cost of accuracy. In A3, overly aggressive compaction caused the agent to repeatedly read files and take more turns. Similarly, multi-token prediction (MTP) in A5 increased token generation speed from approximately 55 to 78 tokens per second but reduced KV cache capacity from 515K to 298K tokens. Much of the speed improvement was offset by repeated prompt processing.

These experiments showed that improving one part of the system can come at the expense of another. There is no universally optimal configuration. The right balance depends on the workload, available resources, and optimization objectives.

## 6. The Agent and Serving Engine Are One System

Agent-side decisions can significantly affect serving engine performance. In A4, the agent's changing status line caused earlier conversation content to be rendered differently, preventing the engine from reusing cached tokens. Preserving earlier reasoning content stabilized the prompt, reduced repeated prompt processing by 53%, and improved model time per token by approximately 15%.

At the same time, the serving engine's capabilities and limitations should influence agent design. For example, in A5, I used SGLang's response continuation feature to recover unfinished responses while reusing cached prompt tokens. These experiments showed that agent and engine optimizations are closely connected and should be considered together.

## 7. Not All Tokens Are Useful

Wasted computation was a recurring problem throughout the assignments. In A3 and A4, the model sometimes spent its entire reasoning budget without producing a tool call or answer. Adjusting sampling parameters helped reduce runaway reasoning. Another source of waste was repeatedly processing context that had been removed from the cache.

In A5, truncated responses accounted for only 7% of all responses but consumed 44% of model time. Continuing unfinished responses rather than discarding them reduced this proportion to 25%, although it did not noticeably improve the solve count.

These experiments highlighted the importance of understanding how much model computation actually contributes to task progress. Generating more tokens does not necessarily mean making more progress.

## AI use

I used AI to help review my work across the four assignments, identify relevant experimental results to support each lesson, and conduct a final review of this blog post, checking for errors and suggesting improvements for wording, clarity, and formatting.