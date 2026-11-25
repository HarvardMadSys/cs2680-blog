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

Assignment 1 was still very useful because it gave me a good starting point to learn what an agent is. It was the first time that I learned about the term "trajectory," where I could see what happened inside a coding agent. Instead of only looking at the prompt and the output, I followed the intermediate steps from reasoning to tool calls. I also saw the traces of failures and sub-agents.

Assignment 2 was my first time designing a coding agent harness on my own. I had to decide about the prompt, tools, state, workflow, and verification, and I learned how to track what the agent was doing throughout the process.

While Assignment 3 made the harness much more like a system that had to handle multiple tasks and limited resources (model speed vs accuracy vs cost) at the same time, I started to recognize the trade-offs among solve count, runtime, and cost. I did many experiments with parallel tasks, different model types, restarts, sub-agents, and different limits on time, turns, and cost. This was also the first time that I started to experiment directly with leaderboard performance.

Instead of calling a model API, Assignment 4 connected the harness directly to the SGLang server. Here, I deployed the model on an RTX PRO 4500 GPU and balanced the harness performance with the server behavior. I worked with server settings such as KV cache, queuing, time to first token, prefill, decode, and concurrency, and saw how they affected speed and solve count with my harness.

Finally, Assignment 5 made my harness as general as possible because it needed to solve tasks beyond the coding exercises of Assignment 4. After a few days of work, I ended up with a harness that was capable of working on a wide variety of different types of tasks (SWE, systems, security, machine learning etc.). I'm quite proud of what I've achieved.

I put a tremendous amount of effort into all of these assignments and I definitely learned a lot from them. I've summarised what I learned below in two broad categories. The first is more on the technical side and the second is more personal (huge thanks to the "How I Used Claude" website, which helped me notice many pitfalls).

## On the Technical Side:

### Keep the Prompt General Without Making It Too Simple

One lesson I learned from these assignments was that the prompt should be specific about how the agent should work, but general about how it should solve the task.

I started with a very general prompt in Assignment 2. In Assignment 3, during one experiment where I wanted to reduce the number of input tokens per request (with the hope that the agent would be faster), I tried a much leaner prompt. However, that version solved only 3/26 tasks on the leaderboard. Later, after I returned to a more complete prompt, I got 13/26. Assignment 4 showed me the other extreme. After listening to students sharing for Assignment 3, I tried adding a structured micro-plan to make my agent be crystal clear about what it was doing, but that version solved only 5/25 tasks on the local tasks, while the previous version solved 20/25. This showed me that more detailed instructions are not always better. I also tried language-specific routines, but their effect was unclear on my harness. Therefore, I did not keep these directions in my final harness.

Assignment 5 pushed me to generalize my prompt further. One early pitfall that I observed was that my old prompt told the agent to delete new test or scratch files before finishing, which worked well in the SWE-Bench. However, in Terminal-Bench, a new file could actually be part of the required result. Thus, in that experiment, the agent deleted files that included real task inputs or results. I later removed the rule and refined my prompt to stop carrying this repository-specific assumption. In the end, my Assignment 5 harness prompt was complete and generalized, with the agent's role and environment, tool behavior, workflow, constraints, time budget, done criteria, verification expectations, and general reliability rules.

### Matching Tools to Model Habits While Handling Tool-Call Failures

The second lesson, and also one of the most interesting things I learned, is that an agent harness should consider what model it is using and whether there is any specific behavior that the model may have. During the student sharing in Assignment 4, one student pointed out that the Qwen model may be more familiar with the tool names that Qwen Code uses, as those tools are developed by the same company. That immediately took me back to something I'd seen in my own runs. In my previous agent trajectory, at various points my Qwen model made tool calls with undefined tool names in my harness. That was the moment I realized those tool names might be picked up during the training phase of Qwen3.6-35B-A3B-FP4. So I started to align my tool names and parameters with the Qwen Code naming convention, keeping the old names as aliases. From that on, my subsequent Assignment 5 runs had absolutely zero undefined tool calls.

### Restart Only When It Actually Helps

When I submitted my harness to the leaderboard, I noticed that for some tasks they were solved almost every time, for some they were never solved, and for some they were only solved occasionally (as a coin-flip). As solve count was important on the leaderboard, I thought a few more attempts at a few of the coin-flip tasks might be worthwhile.

Thus, in Assignment 3 I added a restart feature. Most of the time, it was just a completely fresh restart from scratch, so the performance wasn't great. Worse, sometimes the agent just kept going down the same failed path, taking up more runtime and more cost. By the deadline, I did not have enough time to test and improve this feature at all.

In Assignment 4, I spent more time improving restarts in two ways. First, I added bounded factual restart memory, so that a new attempt could carry forward a small set of useful information from the previous attempt. Second, I made the restarts conditional on the evaluation result and the remaining time. Thus, a near miss would get another attempt, but a task still very far from passing would just stop rather than waste any more time and resources.

I removed fresh restarts in Assignment 5. In Assignment 4, a fresh restart could reset the working tree. This was a problem for Terminal-Bench because it could remove changes that would be graded as part of the final container state.

### Better Verification Instead of More Verification

In Assignment 2, I first learned that simply running a test wasn't sufficient. Sometimes the agent only tested a small part of the required behavior. In other cases, it ignored earlier test failures after a few other tests passed. I therefore enabled my harness to write small behavior checks based on the task requirements.

After learning more about verification from the student sharing in Assignment 3, I wanted to add more verification to my harness for Assignment 4. However, more verification could actually hurt. In one experiment, I built a contract test writer, but it did not solve any additional tasks, and only 3 out of 43 generated tests were judged as effective. Worse, many of the generated tests had problems, especially for Go, where all six contract tests failed to compile.

After a root cause analysis, I found that the problem was that my verification generator itself was not properly validated. A wrong test gave the agent the wrong signal and could even make the solution worse. I therefore dropped this direction.

### Using Task-Level Time Limits Rather Than One Global Stop

In Assignment 4, I noticed that a lot of students had finished their leaderboard run a lot quicker than I had, so I went in to try and reduce my total runtime. I first considered a global stop for the whole run. My first attempt was a 55-minute hard stop, and that run only solved 2 of the 26 tasks. 6 tasks never even started, and 7 just finished with no patch. So a global stop just rudely ends every task at once, which is not optimal.

In Assignment 5, I started to set a time limit for each task. After reviewing results from the earlier runs, I set a 30-minute time limit for Terminal-Bench (all the Terminal-Bench tasks already had their own time limits). If the task limit was 30 minutes or less, I kept it. If it was more than 30 minutes, I capped it at 30 minutes. For the 26 task benchmark, which didn't have any real task-specific time limits, I went with a 34-minute fallback based on the results of the earlier runs. In that case, I just made the run faster by keeping the solve count roughly the same. Thus, as opposed to a global stop, setting a time limit for each task led to more tasks finishing while still ending the unsolvable tasks sooner.

### Tuning the Harness and Server Together

Assignments 4 and 5 showed me that the SGLang server and the agent harness need to work together. At first, in Assignment 4, I opened all 25 local tasks at once, and only 9 of 25 local tasks were solved. Based on the SGLang metrics, the average KV cache use hit 83%, and many model calls waited in the queue for a long time. Later, I reduced the task concurrency from 25 to 5. The average KV cache dropped to 37%, and the number of solved tasks went up to 18 of 25. This taught me that more concurrency isn't always better. After a certain point, it just causes more waiting instead of more useful work.

I spent a lot of time playing with different SGLang settings in Assignment 4. Small decode CUDA graph buckets made a single leaderboard run 29 minutes faster and solved one more task. FP4 KV was another useful tweak, increasing the KV pool from 358K to 540K tokens and reducing the number of lost prefix tokens from 12.0M to 7.4M.

In Assignment 5, I ran into some different issues with longer workloads. One test with a fairly long prompt (around 190K tokens) had the subsequent requests waiting 44-47 seconds before they could start decoding. Setting `prefill-decode-interval` to 2 dramatically reduced the waiting time to about 1.8 seconds with only a 3% increase in TTFT (a great success!). I also had one engine version that decoded roughly 10% faster, but it subsequently crashed due to CUDA OOM. After I added `expandable_segments`, the number of near OOM warnings dropped from 24 to zero, and the lowest free memory went from 33MiB to 395MiB.

Though tuning SGLang can help the harness solve tasks faster, I still believe the leaderboard performance depends more on the harness design. If the harness cannot solve many tasks, uses too many tokens in its prompts, or doesn't manage its memory well, a faster server alone won't make much difference to the leaderboard result.

## On my personal side:

### Learning How to Work Better With Coding Agents

In the beginning, I trusted my coding agent, Claude Code, a lot. When it suggested the next step, I usually just approved it, even if it didn't explain why. I also mostly believed it when it said something had been done. But the more I worked with coding agents, the more time I came to realize they aren't always right. They can misread the scope of the work, make changes that weren't requested at all, or just treat their own assumptions as facts. In Assignment 2, one of Claude Code's mistakes remained in my harness for a week before I eventually tracked it down and got it fixed (according to the pitfalls section from my "How I Used Claude" website).

The "How I Used Claude" website was extremely useful because it pointed out several of these pitfalls in how I worked with the agent. As the course went on, I also learned from the professor and other students during sharing sessions. One important change is that I now ask the coding agent to explain exactly what it changed and show evidence that the change works. When I'm unsure, I ask for a before-and-after comparison. I also tuned the Claude Code reporting behavior. Instead of long paragraphs, I ask for short explanations with tables and plots. I started writing these rules into `CLAUDE.md` so I can reuse them in future projects.

### Questioning the Coding Agent When Its Reasoning Narrows the Scope Too Much

This lesson is different from the first one. In Assignment 3, after several experiments didn't work well, my coding agent kept recommending that I use the Standard model and build a simple agent harness. All the pieces of evidence it was presenting were individually reasonable: the Expert model was expensive, the sub-agents cost more time and hadn't really helped the agent performance, and the agent had found some papers online suggesting that a simple architecture actually worked quite well for Qwen on SWE-bench. I ended up trusting my coding agent without actually checking whether it was in fact getting me to the right result. In the end, I wasn't happy with my rank on the Assignment 3 leaderboard.

Later, during the Assignment 3 student sharing, I noticed that many of the top students' submissions still used sub-agents and Expert models, but they used them in smarter ways that I had never tried. In the Assignment 4 student sharing, I still remember one student saying that we should guide the coding agent's thinking and insist on testing the directions that we believe are worth trying. This was a very important lesson for me. In the future, even when my coding agent gives a reasonable explanation, I still want to question whether its conclusion is too strong. I also need to be more confident in my own ideas and test them before letting the agent narrow the design space too early.

### Running Experiments More Carefully Before Trusting the Result

I learned three lessons about running experiments. The first was to change only one thing at a time. Early in Assignment 3, I changed several features at once, and harness performance got worse. I couldn't tell which change caused the problem, so I later had to test them one by one (which took me more time…).

The second lesson is that one run is not enough to draw any conclusion about the harness performance. Because of randomness in LLM token generation, even with the same harness and the same setup, my harness may still solve a completely different number of tasks or take a completely different amount of time across runs.

Third, local results didn't always match the leaderboard performance. So, repeated experiments are necessary. When time allowed, I resubmitted the same harness package to the leaderboard at least 2 times before coming to a conclusion.

### Learning Better Strategies for the Leaderboard

I had some experience with Kaggle competitions, but Assignments 3, 4, and 5 were the first real leaderboard competitions that I have ever experienced for coding agents. From the student sharing sessions, I learned a lot of tricks and strategies for the agent leaderboard. In Assignment 3, I was quite surprised to see a number of students choosing a small number of the easier (faster) tasks and focusing their harness on these tasks, skipping the much harder (or unsolvable) tasks. At that point, I just let my harness go through every task, which made the run time per task much longer. I also learned about students looking for gaps on the leaderboard and targeting a particular position rather than simply trying to maximize the number of tasks solved or minimize the total run time. That was refreshing to me and completely changed the way I thought about leaderboard competition.

## AI Acknowledgement

For the coding parts of the assignments, I worked with Claude Code and Codex. For this blog post, I developed all the ideas and wrote it myself. I used a translator and Grammarly to help improve my English grammar and wording. I also used Claude Code to help with the formatting and layout of the blog post.
