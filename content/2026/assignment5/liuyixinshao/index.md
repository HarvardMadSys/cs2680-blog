---
title: "My Journey with This Class"
date: 2026-11-22
authors: ["Liuyixin Shao"]
summary: "A great journey. A lot of pitfalls. I learned a lot." 
tags: ["agent-design", "tool-use"]
draft: false
# cover: "cover.webp"   # optional: a figure to show on the listing
---

CS2680 was a great journey for me. When I look back at what I experienced through the assignments in this class, I realize that I learned a lot. In this review, I will discuss what I did, what I found, and what I learned, especially from Assignments 2 to 5.

<!--more-->

Assignment 1 was still very useful because it gave me a good starting point to learn what an agent is. It was the first time that I learned about the term "trajectory," where I could see what happened inside a coding agent. Instead of only looking at the prompt and the output, I followed the intermediate steps from reasoning to tool calls and tool results. I also saw the traces of failures, retries, and sub-agents. This assignment helped me think of a coding agent as a loop instead of a single model call.

Assignment 2 was my first time designing a coding agent harness on my own. I had much more control over how it worked. I had to decide about the prompt, tools, state, workflow, and verification, and I learned how to track what the agent was doing throughout the process.

While Assignment 3 made the harness much more like a system that had to handle multiple tasks and limited resources at the same time, I started to recognize the trade-offs among solve count, runtime, and cost on the leaderboard. I did many experiments with parallel tasks, different model types, restarts, sub-agents, and different limits on time, turns, and cost. This was also the first time that I started to experiment directly with leaderboard performance.

Instead of calling a model API, Assignment 4 connected the harness directly to the SGLang server. Here, I needed to deploy the model on an RTX PRO 4500 GPU and connect the harness behavior with the model-serving behavior. I worked with KV cache, queuing, time to first token, prefill, decode, concurrency, and other serving-side behaviors and settings. I did many experiments to balance the harness behavior with the server behavior and understand how this affected speed and solve count.

Finally, Assignment 5 was the most complicated one because it went well beyond the coding exercises of Assignment 4. My objective was to make my harness as general as possible whilst still maintaining a good balance between solve count and runtime. After a few days of work, I ended up with a harness that was capable of working on a wide variety of different types of tasks (SWE, systems, security, machine learning etc). I'm quite proud of what I've achieved.

I put a tremendous amount of effort into all of these assignments and I definitely learned a lot from them. I've summarised what I learned below in two broad categories. The first is more on the technical side and is about agent harness design. The second is more personal and is about the way I now work with coding agents and run experiments (largely due to the "How I Used Claude Code" website, which helped me notice many pitfalls).

## On the Technical Side:

### Keep the Prompt General Without Making It Too Simple

One lesson I learned from these assignments was that the prompt should be very specific about how the agent should work, but very general about how it should solve the task.

Assignment 2 was my starting point. From the lecture, I learned that the prompt should work across tasks, so I kept mine general and didn't add task-specific guidance.

However, in Assignment 3, because we were competing on the leaderboard, I tried many different ideas. In one experiment, I wanted to reduce the number of input tokens per request, with the hope that the agent would be faster. After researching with Claude Code, I tried a much leaner prompt. However, that version solved only 3/26 tasks on the leaderboard. Later, after I returned to a more complete prompt, one version got me to 13/26. So being general doesn't necessarily mean you go for the simplest possible prompt.

Assignment 4 showed me the other extreme. After listening to students sharing about their Assignment 3 harness, I tried adding a structured micro-plan to make the agent more focused, but that version solved only 5/25 tasks locally, while the previous harness solved 20/25. This showed me that more detailed instructions are not always better. I also tried language-specific routines, but their effect was unclear on my harness. Therefore, I did not keep these directions in my final harness.

Assignment 5 pushed me to generalize my prompt further. One early pitfall that I observed was that my old prompt told the agent to delete new test or scratch files before finishing. However, in Terminal-Bench, a new file could actually be part of the required result. Thus, in one early experiment, the agent deleted files in 3 of 8 finished tasks, including real task inputs or results in two cases. After noticing this, I removed the rule and refined my prompt to stop carrying this repository-specific assumption. In the end, my final Assignment 5 prompt was not short. It still includes the agent's role and environment, tool behavior, workflow, constraints, time budget, done criteria, verification expectations, and general reliability rules.

### Matching Tools to Model Habits While Handling Tool-Call Failures

The second lesson, and also one of the most interesting things I learned, is that an agent harness should consider what model it is using and how that model actually behaves. During the student sharing in Assignment 4, one student pointed out that the Qwen model may be more familiar with the tool names that Qwen Code uses, as those tools are developed by the same company. That immediately took me back to something I'd seen in my own runs. In the trajectory, at various points Qwen would make tool calls with tool names that were completely undefined in my harness. That was the moment I realized those tool names might have been picked up during the training phase of the model. From that point on, I started to align my tool names and parameters with the Qwen Code naming convention, keeping the old names as aliases. After that change, in my subsequent Assignment 5 runs I had absolutely zero foreign tool calls.

### Restart Only When It Actually Helps

When I submitted my harness to the leaderboard, I noticed that for some tasks they were solved almost every time, for some they were never solved, and for some they were only solved occasionally. As solve count was the thing that mattered on the leaderboard, I thought one more attempt at a few of the coin flip tasks might be worth a try.

Thus, in Assignment 3 I added a restart. For most of the time, it was just a completely fresh restart from scratch so the performance wasn't great. What I quickly discovered was that the agent just kept going down the same failed path, taking up more runtime and more model cost. That was when I learned that more restarts do not automatically make the harness better. By the deadline, I did not have enough time to improve this feature at all.

In Assignment 4, I had more time to improve restarts in two ways. First, I added bounded factual restart memory, so that a new attempt could carry forward a small set of useful facts from the previous attempt. Second, I made the restarts conditional on the evaluation result and the remaining time. Thus, a near miss would get another attempt, but a task still very far from passing would just stop rather than waste any more time and resources.

I stopped using a fresh restart in my Assignment 5 harness. In Terminal-Bench, many tasks were graded on the final state of the whole container. Thus, an Assignment 4-style fresh restart could therefore reset useful work already completed. Since leaderboard time also mattered in Assignment 5, I did not want to spend extra time on restarts.

### Better Verification Instead of More Verification

In Assignment 2 I first learned that simply running a test wasn't sufficient. Sometimes the agent would only test a very narrow aspect of the behavior, and sometimes it would change the code as a result of the test but still consider the old test result as valid. I therefore added general requirement based checks to my Assignment 2 harness.

After learning more about verification from the student sharing in Assignment 3, I wanted to add more verification to my harness. However, Assignment 4 showed me that more verification could actually hurt. I built a contract test writer, but it did not solve any additional tasks, and only 3 out of 43 generated tests were judged as effective. Many of the generated tests had problems, especially for Go, where all six contract tests failed to compile.

After a root cause analysis, I found that the problem was that my verification generator itself was not properly validated. A wrong test gave the agent the wrong signal and made the solution worse. So the verifier itself also needs to be verified, and I therefore dropped this direction.

### Using Task-Level Time Limits Rather Than One Global Stop

In Assignment 4, I noticed that a lot of people had finished their leaderboard run a lot quicker than I had, so I went in to try and reduce my total runtime. I considered a global stop for the whole run. My first attempt was a 55-minute hard stop, and that run only solved 2 of the 26 tasks. 6 tasks never even started, and 7 just finished with no patch. Looking at the trajectories, I saw that a global stop just ends every task at once, so it can't tell which ones are actually making progress and which ones are just wasting time.

In Assignment 5, I started to set a time limit for each task. After reviewing results from the earlier runs, I set a 30-minute time limit for Terminal-Bench (all the Terminal-Bench tasks already had their own time limits). If the task limit was 30 minutes or less, I kept it. If it was more than 30 minutes, I capped it at 30 minutes. For the 26 task benchmark, which didn't have any real task-specific time limits, I went with a 34-minute fallback based on the results of the earlier runs. In that case, I just made the run faster by keeping the solve count roughly the same. As opposed to a global stop, this strategy let more tasks finish while still ending the unsolvable tasks sooner.

### Tuning the Harness and Server Together

Assignments 4 and 5 showed me that the SGLang server and the agent harness need to work together. At first, in Assignment 4, I opened all 25 tasks at once, but only 9 of 25 local tasks were solved. Looking at the SGLang metrics, I saw that the average KV cache use hit 83%, and many model calls waited in the queue for a long time. Later, I tried reducing the number of active tasks from 25 to 5. The average KV use dropped to 37%, and the number of solved tasks went up to 18 of 25. This taught me that more concurrency isn't always better. After a certain point, it just causes more waiting instead of more useful work. I also learned that a server benchmark should match the real harness workload based on the benchmark tests that I did.

I spent a lot of time playing with different SGLang settings in Assignment 4. Small decode CUDA graph buckets made a single leaderboard run 29 minutes faster and solved one more task. FP4 KV was another useful tweak, increasing the KV pool from 358K to 540K tokens and reducing the number of lost prefix tokens from 12.0M to 7.4M. The replay was 7.3% faster.

In Assignment 5, I ran into some different issues with longer workloads. One test with a fairly long prompt (around 190K tokens) had the subsequent requests waiting 44-47 seconds before they could start decoding. Setting `prefill-decode-interval` to 2 reduced that to about 1.8 seconds with only a 3% increase in TTFT (a great success!). I also had one engine version that decoded roughly 10% faster, but it subsequently crashed due to CUDA OOM. After I added `expandable_segments`, the number of near OOM warnings dropped from 24 to zero, and the lowest free memory went from 33MiB to 395MiB.

Though tuning SGLang can help the harness solve tasks faster, I still believe the leaderboard performance depends more on the harness design. If the harness cannot solve many tasks, uses too many tokens in its prompts, or doesn't manage its memory well, a faster server alone won't make much difference to the leaderboard result.

## On my personal side:

### Learning How to Work Better With Coding Agents

In the beginning, I trusted my coding agent, Claude Code, a lot. When it suggested the next step, I usually just approved it, even if it didn't explain why. I also mostly believed it when it said something had been done. As I worked with coding agents more, though I came to realize they aren't always right. They can misread the scope of the work, make changes that weren't requested at all, or just treat their own assumptions as facts. In Assignment 2, one of Claude Code's mistakes remained in my work for a week before I eventually tracked it down and got it fixed (according to the pitfalls section from my "How I Used Claude Code" website).

The "How I Used Claude Code" website was extremely useful because it pointed out several of these pitfalls in how I worked with the agent. As the course went on, I also learned from the professor and other students during sharing sessions. One important change is that I now ask the coding agent to explain exactly what it changed and show evidence that the change works. When I'm unsure, I ask for a before-and-after comparison. I also changed how I ask Claude Code to report back. Instead of long paragraphs, I ask for short explanations with tables and plots. I started writing these rules into `CLAUDE.md` so I can reuse them in future projects.

### Questioning the Coding Agent When Its Reasoning Narrows the Scope Too Much

This lesson is different from the first one. In Assignment 3, after several experiments didn't work well, my coding agent kept recommending that I use the Standard model and build a simple agent harness. All the pieces of evidence it was presenting were individually reasonable: the Expert model was expensive, the sub-agents hadn't really helped at all, and the agent had found some papers online which suggested that a simple architecture would actually work quite well for Qwen on SWE-bench. I ended up going with it completely, trusting my coding agent without actually checking whether it was in fact getting me to the right answer. In the end, I wasn't happy with my rank on the Assignment 3 leaderboard.

Later, during the Assignment 3 student sharing, I noticed that many of the top students' submissions still used sub-agents and Expert models, but they used them in smarter ways that I had never tried. In the Assignment 4 student sharing, I still remember one student saying that we should guide the coding agent's thinking and insist on testing the directions that we believe are worth trying. This was a very important lesson for me. In the future, even when my coding agent gives a reasonable explanation based on previous experiments, I still want to question whether its conclusion is too strong. I also need to be more confident in my own ideas and test them before letting the agent narrow the design space too early.

### Running Experiments More Carefully Before Trusting the Result

I learned three lessons about running experiments. The first was to change only one main thing at a time. Early in Assignment 3, I changed several features at once, and performance got worse. Since I couldn't tell which change caused the problem, I later had to test them one by one. After that, I tried to make each experiment answer one specific question.

The second lesson is that one run is not enough to draw any conclusion about the harness performance. Because of randomness in LLM token generation, even with the same harness and the same setup, my harness may still solve a completely different number of tasks or take a completely different amount of time across runs.

Third, local results didn't always match the leaderboard performance. So, repeated experiments are important. When time allowed, I resubmitted the same harness package to the leaderboard at least 2 times before coming to a conclusion.

### Learning Better Strategies for the Leaderboard

I had some experience with Kaggle competitions before, but Assignments 3, 4, and 5 were the first real leaderboard competitions for coding agents. From the student sharing sessions, I learned a lot of tricks and strategies for the agent leaderboard. In Assignment 3, I was quite surprised to see a number of students choosing a very small number of the easier (faster) tasks and just focusing their harness on those, skipping much harder tasks. At that point, I just let my harness go through every task, which made the run time per task much longer. I also learned about students looking for gaps on the leaderboard and targeting a particular position rather than simply trying to maximize the number of tasks solved or minimize the total run time. That was all very refreshing to me and completely changed the way I thought about leaderboard competition.

## AI Acknowledgement

For the coding parts of the assignments, I worked with Claude Code and Codex. For this blog post, I developed all the ideas and drafted the initial wording myself. I used translation tools and Grammarly to help improve my English grammar and wording. I also used Claude Code to help with the formatting and layout of the blog post
