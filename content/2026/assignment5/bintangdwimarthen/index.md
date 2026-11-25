---
title: "Managing Large Language Monkeys"
date: 2026-11-24
authors: ["Bintang Dwi Marthen"]
summary: "Lessons from optimizing LLM coding agents throughout CS2680 assignments."
tags: ["lessons learned", "performance optimization", "infinite monkey theorem"]
draft: false
cover: "cover.webp"
---

Across assignments 2-5, I improved an LLM-based agent under increasing constraints. The main lessons were not only about prompting or the model, but the system should be optimized holistically: harness, serving engine, and budgeting.

<!--more-->

## Preface: Infinite Monkey Theorem

The infinite monkey theorem suggests that a monkey typing randomly for an infinite amount of time will eventually produce a Shakespearean poem. I believe the same intuition applies to AI coding agents: given enough attempts, they may eventually produce a working solution. However, we do not have infinite time nor compute resources. In this course, I was constrained by API costs, execution time, and access to one RTX PRO 4500 GPU with 32 GB of VRAM.

Unlike the monkey in the theorem, an LLM is not totally random. The tokens it produces are based on patterns learned from its training data. Nevertheless, the agent's trajectory can still differ across runs, as a slightly different response may diverge the future trajectories, leading to different outcomes even with the same initial conditions.

There is a certain monkey I believe is worth mentioning: Sun Wukong from _Journey to the West_. He has superpowers such as creating clones of himself from his own hairs. However, in the journey, he often still needs guidance and restraint from his master, Tang Sanzang. In this post, I will use this analogy for agent systems: the LLM provides the raw capabilities, while the harness provides the guidance and restraint needed to turn those capabilities into reliable solutions.

## Giving the Monkey a Harness
![Sun Wukong showing off his golden headband](monkey_king_01_harness_landscape.webp)

In assignment 2, I built an agentic loop with tools for file operations, executing commands, reproduction checks, and completion flag. The harness prevented edits to existing tests and restricted file operations to the task's working directory. The done tool also reran reproduction checks and rejected completion if any checks failed. I continued iterating on this harness in assignments 3-5.

The importance of harness is highlighted in assignment 3, where every student had the same model and serving engine, yet the results can vary significantly depending on the harness implementation. From the leaderboard, the range of tasks solved by students at rank #1 is very wide, from 7 tasks solved to 20 tasks solved. One student's harness may be able to solve more but they spend more time and API cost, while another student's harness may be more efficient but solve fewer tasks.

I also argued that harness should be designed with the serving engine and model in mind. For example, if the serving engine has limitations on concurrent requests, the harness should acknowledge this and limit the number of concurrent requests accordingly (which is the case for assignment 4). Another example is providing common pitfalls for the LLM to avoid, such as known issues with the model's behavior on a particular programming language. This co-design increased my task solve rate up to 21 tasks out of 26 in assignment 4.

**Lesson**: Not only the model and serving engine matter, but the harness plays a crucial role in determining the agent's reliability and efficiency. And the harness should be designed with the model and serving engine in mind.

## The Same Monkey, Different Results? More Monkeys!
![Sun Wukong creating clones of himself](monkey_king_02_clones_landscape.webp)

There is a recurring observation across all assignments: the very same harness and model can produce different results at the same task. This is easily reflected at the leaderboard runs, where one attempt may differ from another even with the same files submitted.

Digging further, we can also classify the tasks based on their success rates: "always solved", "sometimes solved", and "never solved". The table below breaks down the leaderboard's tasks (assignment 4) into these categories. We can see that for my harness, 50% of the tasks are sometimes solved. Therefore, there is a need for multiple attempts to increase the chance of solving these tasks.

| Class | Tasks |
|---|---:|
| Always solved | 6 |
| Sometimes solved | 13 |
| Never solved | 7 |

One such approach is to run the same task multiple times (like Sun Wukong creating clones of himself) to increase the chance of success. In assignment 4, I ran up to 4 parallel attempts for each task. This strategy helps me increase my overall task solves from 8-11 tasks with one track, to 13-17 tasks with two tracks, and up to 21 tasks with four tracks. Another approach is to resubmit the same file multiple times, hoping that it will eventually get a better result (which is the case for me in assignment 4 [17 → 19 → 21 tasks solved]).

However, this strategy does not apply for assignment 3 where students were limited by the API costs. In such cases, running more agents does not help since the cost is very tight ($10 for all tasks).

**Lesson**: LLMs are non-deterministic, so running multiple attempts can increase the chance of success, but this strategy is not always applicable, especially when API costs are tight (or the serving engine does not support parallelism well).


## Making the Monkey Faster Requires the Right Benchmark
![Sun Wukong riding Somersault cloud](monkey_king_04_serving_speed_landscape.webp)

This point is highly related to the previous lesson. Running multiple attempts at the same time requires a serving engine that can handle concurrent requests efficiently. Otherwise, the benefits of parallelism may be diminished due to bottlenecks in the LLM calls.

In assignment 4, I initially used SGLang's serving benchmark for the purpose of measuring how good my engine was. However, I noticed that the benchmark results did not translate to real leaderboard performance. This led me to realize that I need a better benchmark to measure how good my engine will be when it serves the actual leaderboard tasks. A quick comparison of the SGLang's serving benchmark and a benchmark based on SWE-Bench tasks is shown in table below.

| Metric | SGLang | SWE-Bench |
|---|---:|---:|
| Mean queued requests | 10.05 | 2.52 |
| Prompt tokens from prefix cache | 7.9% | 54.4% |
| Throughput | 209 tokens/s | 275 tokens/s |

With a more appropriate benchmark, my coding agent can better iterate on the serving engine. I also argue that parameter tuning for the serving engine can be workload specific as well, one such parameter is the KV-cache eviction algorithm. One paper worth reading regarding KV-cache eviction algorithms is <https://arxiv.org/abs/2609.28870>.

**Lesson**: A benchmark that closely matches the actual workload is crucial for accurately measuring the performance of a serving engine, especially when trying to do parameter tuning.


## Monkey Memory is not Always Reliable
![Sun Wukong reading notes](monkey_king_05_context_memory_landscape.webp)

I tried several ways to reduce redundant context processing. One such way is by utilizing memory from one attempt as handoff context for the next attempt. However, I found that doing so instead caused the agent explores more instead of reducing redundant context processing. One result from my measurement that supports this claim is the reduction in my solve rate from 26/51 to 20/51 when I enable agent memory. This phenomenon is also discussed in class sharing session that memory is not always reliable, unless carefully implemented with an excellent approach.

**Lesson**: Whenever you want to implement a feature, measure its impact on the actual task performance before assuming it will improve the system. A generally intuitive feature may not always lead to better performance when it is not carefully implemented.


## Importance of Traceability
![Sun Wukong inspecting a checklist](monkey_king_06_verification_landscape.webp)

Throughout all five assignments, I actively utilize my coding agent to do the majority of the implementation work autonomously. However, at times it is easy to lose track of the agent's actions and decisions. Maintaining traceability is therefore essential to understand whether the coding agent made the right decisions and to further guide it in future iterations.

One such approach I used is maintaining multiple Slack canvases to track the iterations my coding agent went through. This helps me keep a clear record of what it has tried (and the result) and makes it easier to reason what it should try next.

**Lesson**: When using a coding agent, maintaining a record of its actions and decisions is essential for decision making.


## AI use

AI is used to generate the illustrations in this post. Specifically, I used ChatGPT to generate the illustrations. All text was written by human (Bintang Dwi Marthen), with ChatGPT assisting in detecting typos and grammatical errors.
