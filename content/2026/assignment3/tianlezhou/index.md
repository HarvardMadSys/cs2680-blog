---
title: "Harness Write-up"
date: 2026-10-23
authors: ["Tianle Zhou"]
summary: "The harness makes sure that we are utilizing cheap models to conduct the tasks, with expensive models used only in important points."
tags: ["agent-design", "model-routing", "context-management"]
draft: false
---

Best leaderboard result (#1): 16/26 solved, $0.2456 per solved task, 10:11 per solved task

<!--more-->

## Main components of the harness

**Model tiers.** There would be in total of 4 different model trials that would be conducted in solving the problems. Among the three model tiers (Qwen, Deepseek-V3, and MiniCPM), I only chose Qwen and Deepseek as the models. There would be 4 rounds in solving the task. The 1,3 round only used the Qwen model. The 2,4 run uses a plan-and-execute framework with Deepseek as the planner and Qwen model as the executor.

**Budget-aware Orchestration.** There would be 5 threads keeping pulling tasks. To control the budget, there is a governor that checks if the remaining budget is still sufficient for the next run. Now there is a hard stop at $5.4. For the time budget, we don't allow for more attempt after 215 minutes, and anything should stop before reaching 228 minutes.

**Attempt schedule.** There will be up to four rounds of attempts allowed. For each round, it starts fresh without any memory inherited from previous trials. The process starts with standard model. And then expert writes a read-only plan, standard model implements it. Then standard again. And if the budget allows we allow the expert do the job, otherwise standard. In the end of the task, the agent would re-submit the best-scoring patch. This process is to make sure the cheap model does most of the work and the expensive one is used only at key points.

**Self-check and feedback.** Agent tends to submit a task too early. Therefore, the first "done" message is rejected and the agent is prompted to check if there is anything missed. And after a failed grading, the harness will make a one standard-model call that decides whether the agent should refine the solution or restart, and gives a hint for the next attempt.

## Optimizations and trade-offs

**Model selection.** Selecting the right model to complete the task. There are multiple models to choose. Yet you will have to select the model based on how hard it is to solve the problem. I found that most of the succeeded tasks are solvable with standard model with a few trials. Therefore, the expert model is just used for giving a plan that the standard model is working on.

**Number of attempts.** Usually another attempt raises the chance of solving a task, but costs money and time, and failed tasks already take 59–77% of worker slot time. I've tried predicting “hopeless” tasks up front, yet it did not work. Another observation is that the marginal gains on getting another trial is decreasing. Yet we are seeing that the cost of each round is almost the same with the same model. So the strategy is to stop when the next attempt’s expected value drops below its cost and time. For us that was after 4 attempts.

**Context Management.** From the rule of the api, cached input costs 1/20 of uncached. Therefore, any edit to earlier messages makes the prefix cache missed and we have to pay the full uncached price. I compress old outputs only once every 30 tool results.

## Pitfalls and what helped

**Git reset.** before extracting the patch, the harness undid the model’s commits with `git reset --soft`. It makes the submission an empty one even if model submitted the diff. The problem here is that clearing the git with reset soft will not remove the commits, which makes the git diff an empty one. We only have to use the mixed git reset to remove the history as well.

**Cutting cost by cutting effort.** to make runs cheaper, I tried giving up on a task after 30 turns without progress and used shorter outputs, fewer kept messages. Yet it didn't work out. The model is relatively weak and cannot adjust to complex agent requirements.  What really matters is selecting the right model to use and doing proper cache management.

## AI use

For assignment 3 harness development. Support preparing information sources in write up and video.
