---
title: "rethinking computing"
date: 2026-11-24
authors: ["Ibrahim Khaliliya"]
summary: "I think there is an interesting distinction to be made here between the model's ability to reason and the system's ability to organize that reasoning."
tags: ["agent-design", "testing", "subagents"]
draft: false
toc: true
---

I want to start by saying that I've undergone a fundamental shift in how I think about LLMs and agents in general, and how I will continue to work with these tools from now on (that transformation has been cooking for a while).

I really believe that we as computer scientists should stop treating LLMs as isolated computational machines and start treating them more like Von Neumann machines, not in the literal architectural sense; we should give them their own dynamic memory that is inseparable from them, define specific computation schemes, and by computation schemes, I mean specific "thinking" regimes with specific tools attached to them, and give them the ability to learn from their mistakes and adapt. LLMs are particularly good candidates for such a mission given their ability to write code and interact with computational environments.

Throughout CS 2680, I've experimented with different ways of building such systems, and oftentimes what I thought would give the harness a significant improvement ended up either doing nothing or hurting its performance. On the other hand, some of the more primitive methods I implemented gave me some of my best results.

I want to go over some of the main things I've learned from building these harnesses and what I think their implications are for building agents in general.

## 1. A good solution must not be lost

Due to the nature of LLMs and their high variance, even a SOTA harness can lose a correct solution. What I mean by losing a correct solution here is not that the model fails to arrive at one, but that the model has already arrived at one and the harness fails to deliver it.

I encountered this problem as early as Assignment 2, where in two instances the agent made the correct changes to the repository, but the manner in which I was collecting Git diffs caused the deleted files to be excluded from the final patch. Both tasks failed, and changing a single Git command in the harness made both of them pass.

This problem manifested itself in different ways throughout the subsequent assignments. Oftentimes a good patch would be lost across retries, cancellations, API errors, or problems with the sandbox. I would sometimes allocate more computation to a task and end up with a worse solution than the one I had before allocating that additional computation.

To address this, I introduced a mechanism that would always store the last valid non-empty diff, and another that would keep previously graded patches and allow the harness to revert to a better patch if a subsequent attempt performed worse. I also gave the model a small finishing window if it exhausted its computational budget while still editing the repository. During that window, I disabled its reading tools so that the remaining computation would be spent finishing the patch rather than exploring the repository further.

I think this raises a more general question about how we should allocate computation to agents. Ideally, allocating additional computation to an agent should not come at the expense of the progress that the agent has already made.

Sometimes reverting back to the primitive methods of saving a good patch and delivering it later can give the harness a much bigger push than an added layer of reasoning.

## 2. Exploiting the high variance of LLMs

One of the more interesting properties of LLMs is that we can give the same model the same problem under practically identical conditions and arrive at two fundamentally different solutions.

One way I tried to exploit this property was through resampling. Instead of having the model continue to fix a solution that wasn't working, I would reset the repository to its initial state and have the model attempt to solve the problem again without access to its previous attempt. Naturally, I would only allow this to happen if the harness had enough time left to make another meaningful attempt.

My resampling submissions solved 13, 13, and 12 hidden tasks, whereas my previous best was 9.

I think part of the reason this works is that once the model adopts a certain interpretation of the problem, it becomes increasingly difficult to get it to abandon that interpretation. We can give the model more tokens and more iterations, but much of that computation might be spent trying to reconcile an incorrect interpretation of the problem with the information it is receiving from its tools.

However, in my later experiments, I found that resampling was not always the answer. Across ten fresh attempts with the same expert model, I wasn't able to recover a missed solution. Having the standard model produce an initial draft and then giving that draft to the expert model to repair did, however, yield a successful solution in one instance.

This makes me think that we shouldn't necessarily be interested in exploiting variance for the sake of variance, but rather in how we can induce different computational paths for the same problem.

The question then becomes whether we should allocate our remaining computation to further developing an existing solution or to developing an entirely independent one. I don't think there is a general answer to this question yet, and I think this is one of the more interesting problems in designing harnesses.

## 3. More complexity does not add better performance if not distributed

Adding reviewers, red-teamers, fallback models, and other mechanisms only adds costs and time if those costs and time are not earned by improving results under the same total budget.

I've experimented with multiple verification mechanisms throughout the assignments, many of which didn't yield any consistent improvement. In one instance, introducing an independent test-writing mechanism increased the time per solve by approximately 40% without improving the results.

I think one of the problems with how we approach multi-agent systems is that we sometimes introduce another agent without introducing a fundamentally different computational task for that agent to perform. We have one agent solve a problem and another agent review the solution, but oftentimes both agents are susceptible to making the same errors.

The best way I've found so far to approach this is to have multiple agents performing genuinely different tasks. And by different tasks, I don't necessarily mean giving them different prompts; I mean defining different computational regimes for them, restricting or expanding the set of tools they have access to, changing the information they receive, and defining different objectives for them.

An agent that explores a repository, for example, should not necessarily operate under the same computational regime as an agent that implements a patch. Similarly, the agent responsible for testing a patch should not necessarily be exposed to all the reasoning that led to that patch.

I think the merit of having multiple agents lies in how we distribute computation across them, rather than in how many agents we can get to reason about the same problem.

## 4. Self-checking can reinforce errors

One of the most interesting findings from my later assignments was that the model's own tests were passing on 35 out of 37 incorrect patches.

This is particularly problematic because much of how we design agents rests on the assumption that we can have the model reason about a problem, arrive at a solution, and then have it reason about whether that solution is correct.

But if the model has misunderstood the problem in the first place, what guarantees that the tests it writes are not also a product of that misunderstanding?

I tried to address this problem by moving some of the verification responsibilities from the model to the harness itself. I had the harness independently rerun the model's last test command on the actual submitted repository. I also introduced a mechanism that would run the model's tests on the original repository and check whether they would pass without any of the changes the model made.

A test passing on the original repository does not necessarily make it a bad test, but it also doesn't give us much information about whether the model successfully addressed the particular problem it was tasked with solving.

I also made the harness distinguish between a test that actually passed, a test that was interrupted, and a test that passed before the model made its most recent changes. These are computationally very different states, but without explicitly keeping track of them, we might treat them as equivalent.

I think we should be more interested in giving the model access to new information about the correctness of its solution than in simply giving it more opportunities to reason about its correctness.

## 5. Optimizing one component does not necessarily optimize the agent

Optimizing cost and time has a lot of local minima, and oftentimes we settle for optimizing one feature instead of the overall performance of the harness.

I experienced this quite extensively in Assignment 4, where much of my work was centered around inference optimization.

Initially, I was limiting the harness to 12 concurrent model calls, whereas the inference server could handle 21. Increasing that limit to 20 reduced the accumulated time spent waiting for permits from approximately 18,300 seconds to 2,860 seconds.

However, I found that some other inference optimizations did not translate particularly well into better agent performance. Speculative decoding, for instance, performed quite well in isolated benchmarks, but one of my runs using it solved 12 tasks in 37.4 minutes, whereas another configuration solved 14 tasks in 36.8 minutes.

I encountered a similar problem when I reduced the maximum generation length from 6,144 tokens to 4,096 tokens. Naturally, I expected this to reduce the amount of time the model spent generating, but it actually increased model time by 29%. The reason for this was that the harness would discard truncated generations and have the model generate them again. I was effectively paying for the same computation multiple times.

The solution was not to further optimize generation length, but to change the way the harness dealt with truncated generations and allow the model to continue them.

Another instance of this was when I tried to optimize the memory usage of Mamba's cache. I initially thought that the cache had run out of usable space because the number of available slots had dropped to zero, whereas many of those slots contained states that could be evicted. My attempt to save memory by dropping interior states ended up breaking prefix caching and introduced more computation.

What I find particularly interesting about these examples is that the problem oftentimes did not lie in the component I was trying to optimize, but in how that component interacted with the rest of the system.

We should ultimately be optimizing for the number of correctly solved tasks under a given computational budget, and not necessarily for the speed at which the model generates tokens, the amount of memory it occupies, or the number of calls we can make to it.

## 6. How much of an agent's computation should be delegated to the LLM?

This brings me back to the argument I made at the beginning of this post.

One of the things I found myself doing more and more throughout the semester was taking responsibilities away from the model and giving them to the harness.

The harness itself would keep track of the patches, determine whether enough time remained for another attempt, determine whether the model's tests were still valid, and restrict the set of tools available to the model depending on what stage of computation it was in.

None of these things necessarily required an LLM to reason about them.

I think there is an interesting distinction to be made here between the model's ability to reason and the system's ability to organize that reasoning. Oftentimes we delegate both of these responsibilities to the model, whereas the latter can, at least partially, be dealt with programmatically.

This is what I mean when I say that we should treat LLMs more like Von Neumann machines. I am interested in constructing a computational environment in which the model's memory, tools, and manner of computation are not merely defined by a static prompt, but are dynamically determined by the state of the system and the problem it is trying to solve.

The memory of such a system should not merely consist of the conversation history of the model. It should also consist of previous attempts, their outcomes, the information acquired throughout those attempts, and the computational state in which those attempts were made.

Similarly, giving a model the ability to learn from its mistakes does not necessarily mean updating its weights. We can also change the computational environment in which it operates based on the mistakes it has previously made.

I think there is a lot of room to explore how much intelligence we can extract from a model by changing the architecture around it without making any changes to the model itself.

## Conclusion

Perhaps the biggest thing I've taken away from this class is that I've become much more interested in how we organize computation around LLMs than I was at the beginning of the semester.

There is a natural tendency to try to solve the limitations of these models by having them reason for longer, introducing more agents, or resorting to more capable models. But throughout the assignments, some of my best improvements came from preserving computation that had already been done, distributing computation differently, or simply preventing the model from performing unnecessary computation.

I don't think we've exhausted what we can do with the intelligence that these models already possess. And I think designing the computational architecture through which we can better utilize that intelligence is a very interesting problem in its own right.

## AI use

OpenAI Codex formatted the supplied post for the course blog, checked the Hugo preview, and submitted the pull request.
