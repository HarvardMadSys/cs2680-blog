---
title: "Why did my agent hand in an empty patch?"
date: 2026-11-24
authors: ["Holden Schermer"]
summary: "An empty patch sent me looking through my agent’s logs. Over four assignments, I found several reasons a run could end before the model had done useful work."
tags: ["agent-harness", "inference", "terminal-bench"]
draft: false
---

By turn three of an Assignment 2 run, my agent had figured out why an equals sign in a trailing comment could crash isort. Ten turns later, the run ended with an empty patch.

The last API response had no text or tool call, but it did include `finish_reason="length"`. Qwen returns its reasoning separately from its final response. On turn 13, the reasoning used up all 12,000 output tokens. My loop saw the empty response and stopped the run before the model made an edit.

## Retry costs

I found at least one cutoff like this in 22 of my 66 traces. I changed the loop so that after a cutoff, the model got a larger output budget and a prompt to continue with a tool call. On the isort task, the agent went from passing 1/4 runs to 2/3. The sample was small, so I went back to one of the passing traces. All four edits came immediately after turns where my original loop would have stopped.

In Assignment 3, my goal was to see how cheaply I could solve at least seven tasks. In an early run, about 60% of my API spending went toward long reasoning and replies that ended without an action. Increasing the output budget made those turns more expensive. I capped reasoning-enabled replies at 3,500 tokens and retried with thinking turned off if the reasoning used up the reply.

I kept retries after a failed grading. In one local run, the agent had five failing tests, used the feedback to revise its patch, and passed on the next grading. That seemed worth paying for. I also checked whether the patch had changed so I could skip grading the same code twice.

My best-ranked submission, #13, solved 10/26 tasks at 9.1 cents per solve. Submission #16 got the cost down to 7.9 cents per solve and still cleared my seven-task target, but it solved eight. I’d pick #16 if I were only trying to meet the minimum as cheaply as possible. I preferred #13 overall because it fixed two more tasks. Several settings changed between the runs, so I couldn’t attribute those two solves to a particular change.

## Rerunning tests after an edit

On another Assignment 2 task, the agent changed a call site in Ansible and finished without running the relevant tests again. That edit broke 21 tests.

I first tried to detect file changes by checking shell commands with regular expressions. That gave me false positives when a command looked like it would modify a file but left the contents unchanged. I ended up hashing the working tree every time the agent ran tests. When it called `done`, the harness could tell it exactly which files had changed since the last test and ask it to rerun the relevant tests. The Ansible task passed with that check in place.

## From 8 local tasks to 26 on the leaderboard

My first Assignment 4 run solved 0/8 local tasks in nine minutes. Six patches were empty. I found I’d left the eight-cent task budget from Assignment 3 in place. Even though every call now went to the same model on my GPU, the pricing code still charged each one at the old expert-model rate. My harness was cutting off attempts based on a cost I wasn’t paying.

After removing the dollar caps and reworking the harness, I got seven of eight locally in 29 minutes. The leaderboard run solved one of 26 in 54 minutes. Disk space had limited me to eight local tasks, and the leaderboard had different tasks, so those scores alone couldn’t tell me why. I built a test with 26 conversations that grew a little each turn, the way my agent’s conversations did.

That test helped me understand what the GPU was spending time on. Each request included the conversation so far. When its beginning was still in the server’s cache, the server could reuse work from the previous turn. With conversations growing to 35,000–58,000 tokens each, the GPU’s roughly 391,000-token cache could only hold so many of them. Opening more tasks meant some of them spent their next turn waiting for the server to process text it had already seen.

In my synthetic comparison, the default server reused about 9% of the prefix tokens. Keeping evicted prefixes in host memory and serving requests with the longest cached prefix first brought that to about 78%. I also tried mixing the work of reading new prompts with the work of generating replies. The first token arrived sooner on average, down from 25.6 seconds to 18.3. But the same 208 requests took 390 seconds to finish, up from 371. If I’d only looked at how quickly each reply started, I’d have kept a change that made the whole batch slower.

I also reran my best Assignment 4 configuration. It went from 11/26 in 118 minutes to 9/26 in 129 minutes with the same settings. That gave me a sense of how much the result could move on its own. Next time I’d repeat a run before deciding that a change was responsible for one extra solve.

## Why v5 closed nine tasks early

For Assignment 5, I gave v5 a 25-minute deadline, let it keep up to 30 tasks open, and turned off separate reasoning. It solved 24/89 Terminal-Bench tasks in 23 minutes and 7/26 tasks on the separate software engineering benchmark in 17 minutes. In the Terminal-Bench results, nine tasks ended in about a second each. All nine had zero model turns.

With six minutes left, for example, the scheduler could still open a task because its cutoff was four minutes. The worker then reserved two minutes to finish, which left four minutes for the task itself. It needed at least five to start. That explains how a Git server task and an eigenvalue problem both finished in about a second. Neither made it to the first model call.

I’d test that boundary with a fake clock before spending another GPU run on it. Then I’d compare how many tasks stayed in the queue, how many got a first turn, and how many passed. Making the scheduler require seven minutes could clear up all nine zero-turn entries simply by leaving those tasks unopened. Both outcomes count as unsolved on the leaderboard.

If I could add one column to my Assignment 2 results now, I’d record why each run stopped. On isort, the last API response explained why the agent needed another turn. On the nine Terminal-Bench tasks, I could work out what happened from the scheduler settings alone. Both showed up as failures in my results, but I’d debug them in completely different places.

## AI use

As the [course policy](https://cs2680.com/policy.html#ai-policy) requires: I wrote this post myself. I used Claude Code (Anthropic) while working on Assignments 2 to 5 to write and debug the agent harness code and to pull numbers out of my run logs. The writing and the conclusions are mine.
