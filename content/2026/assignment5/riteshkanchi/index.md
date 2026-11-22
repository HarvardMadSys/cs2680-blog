---
title: "A balancing act of constraints: lessons learned from the course"
date: 2026-11-23
authors: ["Ritesh Kanchi"]
summary: 'The assignments as a whole can be encapsulated or characterized as a "balancing act" of constraints, which varied and changed throughout the course'
tags: ["simplicity", "constraints", "future"]
draft: true
---

There were a lot of things I learned thorughout this course, and I think that the assignments as a whole can be encapsulated or characterized as a "balancing act" of constraints, which varied and changed throughout the course. Certain constraints forced me to make specific trade-offs, whereas others provided more freedom to explore and experiment.

These constraints often included:

- Cost
- Time
- Solvability
- Models
- Engine
- Hardware

And each of these constraints had different effects on what was built and how it was built. In the following lessons, I go through a few of the the things I learned, categorized by the constraints that I had to work with.

## Scaffolding agent understanding and knowledge

Assignment 2 was the assignment where I definitely felt the most constrained, both by my knowledge of coding harnesses and the capabilities of the models I was using. At some times during the assignment, it felt as if the model was really good, and in others, it felt like the model was really bad. Throughout my test runs, I kept noticing a similar pattern: when the harness was provided with the necessary context to solve the problem, it was able to do so effectively --- this seems like a fairly obvious statement, but it was something that I had not considered before. This led me to two harness design decisions:

### RepoMap

RepoMap, is a map of the repository given to the harness, which allows it to determine which files to operate on, and which files to ignore. It pulls backticked terms and code-looking terms from the task and uses them to find the relevant files in the repository. Then, it checks the interface and source files to find relevant methods to operate on, provided into the initial prompt.
This was a very important addition to the harness, as it allowed the harness to focus on the relevant files, rather than wasting time and resources on irrelevant files. In Assignment 2, when working on fixing the React Compiler's manual memoization, the harness kept guarding the wrong location and only patching `FinishMemoize` not `validateInferredDep`. Furthermore, the harness was not aware that there was an error, since all the tests were passing. Adding RepoMap allowed the harness to find the right methods to operate on, such that `validateInferredDep` was patched with the proper guard. At one point, I tried bundling `ctags` as an additional tool to help the harness find the right methods to operate on, but this was not as effective; I thought about using it as a way to help the model do continous searching throughout the codebase, but found it to be a fairly unhelpful addition, as the harness never really utilized it.

### RepoDocs

RepoDocs, looks for `AGENTS.md` and `CLAUDE.md` files that are present in the repository, and uses them to provide additional context to the harness. Given that more and more repositories are using these files to provide agents with standardized information about how to operate on the repository, this felt like a very timely addition to the harness. It provides the needed information as specified by the codebase maintainers. Similarly, in the Ract Compiler, there was a bug with the memo cache having stale imports. On initial runs, the harness spent a significant amount of time (71/75 turns) re-reading files it had already found and figuring out how to run the tests. Adding RepoDocs gave the harness information on how to run the tests much earlier, as the testing instructions were specified in `CLAUDE.md` explicitly. This, along with RepoMap, enabled the harness to begin editing as soon as turn 30-42 rather than turn 71-75.

## Time versus cost

In assignments 2 and 3, it felt like the primary constraint was first cost, and then time when trying to reach a solution. This chanegd in assignments 4 and 5, where the primary constraint was no longer cost, but only time. When it came to hosting and serving our own models, and cost no longer a factor, it felt like I could explore more and try different things, rather than being limited by the cost of the models I was using (expert models, for example, in A3 were something I did not use significantly). If anything, I spent a lot of time on assignments 2 and 3, compared to assignments 4 and 5, since these constraints shifted. Task solvability was always a high-level constraint, but the time and cost constraints were more immediate and pressing. For example, in assignment 3, I added a turn budget and primarily relied on the standard model for model calls (and using the expert model sparingly for failing diagnoses). Similarly, I only used reasoning on the first and on critical turns, helping both time and cost. But with assignment 4 and 5, I got rid of any changes that would have reduced cost, and instead focused on the model serving engine. By redistributing the "labor" from the harness to the engine, and focusing on how the engine could best support the harness (this was my main takeaway of Assignment 4).

## keep it simple, stupid (or not?)

As I worked towards Assignments 3, 4, and 5, I couldn't help (and still feel) as if there are poor returns on making agent harnesses overly complex. If provided with too much context, the model can become confused and not know what to do with all the information---potentially making biased, incorrect decisions. If provided with too little context, the model can become confused and not know what to do with the information it has---potentially making unbiased, incorrect decisions. To some extent, the proper amount of context and flexibility is in the middle of these: providing foundational scaffholding, and tooling that enable the harness to operate on the model. At the end of Assignment 2, I had felt that my agent was overly complex. When looking at existing, successful harness architectures online, I had found that a majority of them had simple harnesses, and that the model was doing much greater lifting. Obviously, we were not designing a harness around a off-the-shelf model, but do the same ideas apply? In this regard, I am unsure --- a weaker model may rely or need more scaffolding and tooling to operate effectively, whereas a stronger model may not need as much scaffolding and tooling to operate effectively. Maybe this is an open question for the future, especially when we consider the increasingly capable on-device and open-source models that are being developed. The intermingling of model, engine, agent, and harness all play a role in the overall effectiveness of the system, and I think that this is something that will be explored more in the future, as discussed in the next section.

## A future of dedicated agent harness architectures

I feel like my biggest takeaway from this course is that I believe that the future will orient around domain-specific, dedicated agent harness architectures. A lot of our current harness solutions are general-purpose --- the tasks in the course that we tested against often required a lot of different capabilities and operated on various languages and frameworks.
Especially once we got to engine serving, I began to realize that it's not only about the harness or the model of choice, but about every component of the system working in tandem. While `SKILLS.md`/`AGENTS.md` are great ways to provide some of this specific knowledge to scaffold the agent and help it, the harness itself was not necessarily the best solution for every task. Similarly, while it would be great to have a harness that could parse through an entire codebase effectively, I can't imagine that this scales well to every codebase, and that there are likely better solutions for specific applications.
What does this mean for the future of harnesses? Well, for one, I think that fine-tuned models to specific languages and frameworks will begin to be the norm, such that companies will be able to provide harnesses that are specifically designed for their codebases, rather than relying on a general-purpose models that may or may not work well for their specific application. Then, the harness can be designed to work with the model, and provide tools for these codebases' specific needs.
In my own experience, using agentic harnesses with established codebases tends to be much mroe successful in an additive sense, rather than in the case of debugging or refactoring. With such codebases, given the greater context available, I've noticed how newly-generated code tends to be in the "flavor" of my own handwritten code for greater understanding, rather than greenfield code that lacks this foundational readability and understanding.

## AI use

While AI use was permitted throughout this course for the sake of building, this blog post has been written without the use of AI.
