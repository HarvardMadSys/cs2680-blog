---
title: "Learnings from Iterative Harness and Engine Optimizations"
date: 2026-11-25
authors: ["Eric Gong"]
summary: "Engine and Harness Optimizations Act on Different Aspects of Agent Performance, but they must co-evolve: the design of one closely influences what optimizations are optimal in the other"
tags: ["Agent-Design", "Tool-Use"]
draft: false
# cover: "cover.webp"   # optional: a figure to show on the listing
---

The primary insight from the completion of the assigments in question is that designing an optimal Agent (model, engine, and harness) cannot be executed peicewise: the design must be holistic, and each component must be iteratively improved and tested alongside all other components of the Agent System. 

Specifically, the choice of the model will influence what strategies are possible and feasible to be implemented on the Harness (slow methodical thinking? Planning? Just Do It?), and as a result, the specifics of the Harness design will influence the optimizations that will improve the Engine. While it is true that the Harness has the most direct impact on task completion, not the Engine, and the Engine merely makes the Harness have liberty to complete more tasks in the same alloted time, the improvements to the Engine, the sort of optimizations that will enable inference to be faster, depends heavily on the type of strategies used by the Harness, which itself depends on the Model.

<!--more-->

## Harness Strategy Determines Engine Optimizations

The most successful runs across Assignment 4 and 5 utilized a very simple harness that required minimal thinking, and dedicated a majority of effort towards code generation. This strategy created a profound impact on the degree to which specific ablations and optimizations were effective for the Engine. For instance, one of the most successful strategies for reducing latency on the Engine-side was speculative decoding. One can specify the number of tokens to speculate before the engine uses an inference pass to accept or reject the speculated tokens. Generally, it is inefficient to go beyond 2 tokens, as on average the third token is rejected sufficiently often to not be worth speculating. 

However, in the context of a Harness that primarily generates code, the speculative pass can generate 3 tokens with the fourth token being not worht speculating: this increase of one token appears trivial, but is responsible for a noticable decrease in latency in the harness. Therefore, we see that a strategy that may prove ineffective on general traces may prove highly effective in specific usecases: hence, the specifics of the Harness dicate what engine optimizations are effective.

## Engine Optimzations determine Harness Strategy

Assignment 4 gave us the liberty of viewing essentially all tasks at the start, and keeping all open for the full 4 hours. As such, one could imagine a Harness that would just start separate threads for each task, allowing all tasks to be completed simultaneously. However, the Engine cannot handle this. The Engine's total throughput would drastically decrease as the total number of concurrent queries exceeded around 8. Hence it was more efficient to reduce the number of simultanous tasks attempted at once so as to increase net throughput on the tasks that were being attempted. Therefore, it became necessary to implement various scheduling and termination metrics in the Harness, as a result of the limitations of the Engine. 

## Model Selection Determines Harness Implementations

One particularily surprising failure case I observed early on was the model's inability to follow the Harness tool call specifications: a large number of tool calls failed due to improper formatting, resulting in substantial wasted inference time as the model reformatted (and repeatedly failed to correctly format) the tool calls. After investigation, it appeared that the model was often relying on tool call specifications from its training data, as opposed to the ones specified by the harness. While a more sophisticated model may have no issue following Harness specifications, a small, FP4, no-think model struggled. Therefore, instead of designing tools that I believed would be useful, I designed the Harness to follow the tool calls that the model would expect. This ultimately increased the efficiency of the model, as it now rarely had failing or mis-formatted tool calls.

## Harness Strategy and Engine Limitations Determines Model Selection

After determining a Harness Strategy in Assignment 4, with the ability to select a model of our choice in Assignment 5, the selected model naturally needs to be one that is most closely aligned with what the harness can leverage, and what the engine can efficiently host. Ultimately, identifying that compute wasnot a bottleneck, a dense model was acceptable, and given that it made sense to optimize VRAM space, a dense model, where all weights on VRAM would be activated in each pass seemed more efficient than a sparse activation MOE model. In addition, for a harness strategy that involved mostly one-shot coding, it becomes important that we choose the best model that does not greatly decrease inference speed, as the ability to make multiple independent attempts within the alotted time limit is one of the main advantages of the on-shot strategy.

## General Synthesis of Insights
For designing an Agentic System, a high level strategy must be first determined, and then that strategy can be optimized on all dimensions: Model, Harness, and Engine. Each part influences the other: the choice of adopting a no-think harness makes specific engine optimizations far more helpful than general benchmarks suggest, the choice of model determines what tools the harness would need (which itself is only important in the case of a no-think harness that limits the model's ability to make use of independent harness tools), and the bottlenecks in the engine help inform what sort of model is most useful. All three of these dimensions influence different aspects of Agentic System performance, but are all, at their core, necessarily interconnected.

## AI use

AI was used to implement the various model, harness, and engine ablations that iteratively improved the Agentic System to its current state. The actual ablations to test were based on a combination of my research, prompting Claude to research, as well as listening to the presentation of peers who shared what worked and what failed on their successful agentic systems. 