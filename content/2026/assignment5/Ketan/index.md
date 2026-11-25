---
title: "Agents are People Too"
date: 2026-11-24
authors: ["Ketan Raghu"]
summary: "Agents are an extremely powerful technology with broad spanning uses, but are still subject to their own limits. Both how you use an agent and how an agent is designed can drastically impact the ability of an LLM to solve a task."
tags: ["subagents" , "agent-design" , "showcase"  , "testing" , "tool-use"]
draft: false
toc: true
# cover: "cover.webp"   # optional: a figure to show on the listing
---

Agents are an extremely powerful technology with broad spanning uses, but are still subject to definable limits (like people). Both how you use an agent and how an agent is designed can drastically impact the ability of an LLM to solve a task.

<!--more-->

## Start Early
<!-- Probably the biggest lesson I learned, other courses typically tell you to start early because it takes a substantial amount of time to find a sufficiently clever solution to a problem, but this course made it possible to interact with real-world evaluation structures and highlighted how much more progress can be made by parallelizing workloads and how important good evaluation is to improving an agent -->

<!-- What you did, what happened and what you learned. Use your own measurements and examples. -->

The value of starting early is probably one of the biggest lessons I've taken from this course. This course demonstrated better than any of my other courses how starting early is not a benefit, but a necessity when developing AI systems at scale. I didn't take advantage of how early I could start in the earlier assignments, especially in assignment 3 where I started late and did not get to test out all of the solutions I wanted to try on the leaderboard. Typically, the value of starting early comes from having time to figure out a sufficiently clever solution, but the solution is not strictly dependent on how much time is used. In this course, starting earlier meant having more time to run different submissions, meaning more evaluations, meaning we could run more frequent experiments and better isolate which features caused improvement and estimate by how much.

I think I took advantage of this the most in assignment 4 and 5 where I focused on hitting the baseline with a less complex submission, then used the remaining time to run experiments on the grading server to gauge how my agent would perform in the true environment (which I learned in assignment 3 and 4 that this gave much more valuable feedback than a local simulated environment).

This course also more closely reflected real-world constraints, and highlighted how much can be done in parallel. For example, I could make a submission, use toy experiments locally, then incorporate the submission evaluation with the results from my local experiments to further improve the agent. Historically, I have tried to isolate long evaluations in my work to run overnight, but this course made me realize how much time that was adding to my work, when I could be actively exploring other strategies.

## Focus on Experimentation before Implementation

<!-- Note that I started this course by treating the tools like short-term products instead of doing an R&D process -->

I treated the first 2 assignments more like short-term products that could be developed directly. This made it a lot harder to isolate changes and figure out how they changed the agent performance, so as I continued developing it was harder to figure out what was going wrong between all of the agent's features.

Later on I realized the assignments require more R&D and started working on building out experimentation to direct the implementation instead of implementing directly. In assignment 3 I made not explicit mention of experiments and instead tried multiple direct implementations. Assignment 4 I explicitly used experiments to isolate the cause of failed submissions. Assignment 5 I expanded this the most with a specific designation and focus on experiments with better tracking, subagents as critics, and was more strict on not not attributing results to run-to-run stochasticity. Using Claude to analyze my old sessions, I only had one explicit mention of "experiment" in assignment 3, but told the agent to experiment in 17 prompts in assignment 5. 

Some of the successful experiments in assignment 5 were testing the number of workers to optimize speed vs solved. Achieved up to 39 solved with 12 workers in just under 2 hrs, compared to 24 solved with 22 workers in 18 minutes. Similar experiments were run to determine how to set a max number of steps, how many solves could be achieved without a second look on failed tasks, and more. These experiments helped isolate which changes contributed to which effect (speed vs solve count). Some other experiments also helped estimate run-to-run noise. For example, one submission achieved 39 solved, but the next with an increased step limit only achieved 33, indicating that the first run was lucky. Some other experiments were prefix caching vs appended messages, KV cache cliff, speculative decoding tradeoff.

## Agents are Stochastic

<!-- Before this course I didn't realize how stochastic agents can be, even frontier agents like Claude Code + Sonnet 5.5 -->
<!-- I treated them as semi-deterministic tools, or at least tools that could be made deterministics by adding more features, tools, skills, etc. -->

Before this course I didn't realize how stochastic agents were. My assumption was that stochasticity could be mitigated with more or higher complexity tools, skills, etc. but when trying that in assignments I saw that was not the case at all. Specifically in assignment 2, I tried to improve results by increasing the number of tools available, but this seemed to overwhelm the model resulting in a regression from scoring 7/10 to 6/10 or less.

This also appeared consistently in every assignment, even re-running the same file changed the outcome. In assignment 5, this meant jumps from 39 to 33 solved, or 19 to 24 solved in the same time limit by the same file, or a minimally changed file.

I found that stochasticity could even show up on frontier agents, albeit much more rarely and typically resulting from an underspecified initial prompt. Having previously done research on algorithm evolution frameworks using LLMs like AlphaEvolve or open-source CodeEvolve, this should have been intuitive to me, and also informed how I used agentic frameworks on the future assignments to focus on breadth instead of only depth (this was also informed by the student usage presentations and how-i-used-claude).

## Developing Agents 

<!-- Without needing to be said, this course has taught a lot about developing AI agents -->
<!-- One of the areas I've been wanting to do more research in is local/small-agent development and deployment, and this course was a phenomenal platform to pursue that -->

Without needing to be said, this course has taught a great deal about developing AI agents. Including basic harnesses from assignment 2 using a model from an API to solve fundamental agent problems. Then in assignment 3 exploring concepts like escalation, task frameworks, incorporating tools, and building out a stronger cost-optimized harness. Then assignment 4 addressing how the agents are actually served which significantly highlighted that agent serving cannot be considered as just a blackbox that can handle unlimited bandwidth. Lastly, assignment 5 which put everything together and allows for extending any leftover exploration/untested strategies and new approaches that were not able to be fleshed out in the previous assignments.

Agents often fail silently, which can be tricky to find. In assignment 4 this came from thinking tokens exhausting the output budget which resulted in no usable plans being produced causing tasks to fail more often. In assignment 5, harness-appended messages broke the prefix cache. Garbled tool calls indicated a need for strict grammar (occasionally the model would produce malformed tool calls that would be read as functions, using SGLANG tool strict level 2 and disabling prefill cuda graph fixed this). Also focusing on simple changes like concurrent task limits, task escalation (task ladder), timeouts, etc. often yielded much larger improvements than complex changes like experimenting with speculative decoding. Although after tuning simple changes, complex changes could be used for further increases or decreased run-to-run noise (although this was not directly tested).

## Don't Under-Rely on GenAI

<!-- However, modern GenAI are still more capable than I gave them credit for before this course, but it matters significantly how you use them -->
<!-- At the start I didn't think much of the first few lectures (100x Engineer), but it does make a substantial difference -->

Coming into this course, my GenAI habits were very conservative. Typically I never used auto mode and always monitored my sessions to accept each separate request. I've since learned that a lot of that monitoring can be leveraged over spending more time on the prompt (to avoid underspecification) and monitoring the agent's trajectory for the first couple commands, or first few minutes for long run tasks. Learning how much to use GenAI and for what, such as monitoring and well-defined experiments drastically increased how fast I could develop my agent.

This helped a lot with general productivity. Specifically being able to run well-specified toy experiments autonomously such as changing the number of concurrent tasks in assignment 4 and having a subagent read and summarize the results, tuning hyperparameters, or even just having a subagent explore an idea that doesn't require a lot of attention like testing different starting prompts. Similarly, Claude Code's ability to use monitors helped a lot with running long tasks without being at my laptop consistently by simply having an agent monitor if a task failed and have it automatically restart without.

With each progressive assignment the amount I used GenAI increased, but how I used it changed significantly. In the first few assignments, I was using it to try to directly implement the solution, but in later assignments I used it to run parallel experiments and build reports I could analyze to determine what changes were doing the best. Generally, I think I learned that GenAI can be used to efficiently explore and combine many well-defined ideas simultaneously, and that agents like Claude Code are already capable enough to run a 'bootleg' evolution setup to increase exploration breadth. In assignment 2, I used about 0.5M output tokens and no subagents, and my prompts were directed to implementing different features directly. For assignment 5, I used almost 9M output tokens roughly 7.3M of which come from subagents running experiments and analyzing the results, while my main session output tokens did not increase as significantly between assignments 3 to 5. The most significant jump was between assignment 3 (1.13M main session output tokens, 1.1M from subagents) to 4 (1.16 main session output tokens, 5.71M from subagents) when I first started using subagents to explore well-defined experiments and try different strategies.

## Don't Over-Rely on GenAI

<!-- Even modern GenAI become tunnel-visioned and poorly assess issues -->

Similar to not underrelying on GenAI, this course also helped me tune how to not overrely on it. Assignment 4 in particular demonstrated that GenAI can become tunnel-visioned on a goal and still needs to be monitored for any exploration/intentionally underdefined task. This was an issue early in assignment 4 when I had a subagents exploring specific strategies. For example, one strategy using a safe goal to try to achieve the baseline and another for a stretch goal to try to exploit the scoring criteria (without breaking the rules). Both strategies tunnel-visioned their specific goals for all changes and were bottlenecked by trying to run all 26 tasks at once. I caught this error after looking at the solve times for each task in the first 2 runs and found that the agent had already used ~5.44M output tokens exploring strategies that had the bottleneck because they were not explicitly told to test the number of active tasks.

## Local vs Grading

Figuring out how to most accurately test the agent locally was very important. I initially assumed that the local environment and grading environment would be similar enough that I could run experiments or test evaluations directly and use the results to inform my graded runs, but my local hardware differed significantly from the grading environment so this was not the case. One of the biggest issues I ran into with assignment 3 and 4 were that full runs of the sample tasks took a long time, but were not perfectly representative of the grading environment or tasks. I tried to mitigate this on assignment 5 with toy experiments focus on things that could be tested then scaled instead of trying to scale from the start. Simulated loads on the GPU also helped a lot to replicate what 26 concurrent tasks (assignment 4) could look like while my laptop only had the capacity to run 5 actual tasks. This saved a lot of time, but I still have not figured out how to best model the environment to reflect the grading server. I think this further highlights the importance of effective evaluation pipelines in real-world settings. Being able to evaluate in the deployment setting is costly so it is important to maximize the information yield.


## AI use

AI was used to comb past Claude Code sessions and help refresh/recall the biggest changes between assignments in methodology, experimentation, and technical implementation. AI was also used to compile references and evidence from sessions and previous assignments for the video. Note that AI was NOT used to directly write any parts of this blogpost.