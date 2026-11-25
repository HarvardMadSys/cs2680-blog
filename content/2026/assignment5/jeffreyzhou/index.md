---
title: "Thinking from First Principles"
date: 2026-11-24
authors: ["Jeffrey Zhou"]
summary: "After assignment 2 I thought that the way to make better agents was to build better harnesses. Now I think the way to make better agents is to empirically measure what works and carefully change one thing at a time."
tags: ["agent-harness", "measurement", "context-management", "benchmarking"]
draft: false
cover: "cover.webp"
coverAlt: "A sprawling grey machine of pipes, gears, gauges and scaffolding fills the left of the frame; on the right, a hand turns the single dial of a small crimson device on a workbench, beside a ruler and calipers"
---

I've just gone through assignments 2-5 (coding agent, make it cheap, serve it yourself and benchmark) and I wanted to share a few learnings that I had.

<!--more-->

## 1. Keep it Simple Silly

For assignment 3, I learned to keep it simple. I spent 1.5 weeks building a really fancy harness with lots of routing policies, context policies, audits of audits etc. In total it was 4700 lines. In the last few runs, prior to submitting it was running 0/5 and 0/3 locally but spending the max <span>$0.55</span> on each task. On the day of the deadline, I quickly built a new harness that was only about 900 lines. It had a cheap first pass, without thinking. Then, for tasks that were not solved by the first pass, it used a more expensive model to solve them. That afternoon, the new harness solved 3/5 for <span>$1.81</span>. A few runs later, it solved 4/5 for <span>$1.48</span>.

To think about how to improve my harness, I started reading into the model prices. The expensive model was <span>$2</span> input per million tokens and <span>$10</span> output per million tokens. It worked out that a full first pass on a task with the cheap model was only <span>$0.015</span>. A single phase on the expensive model was <span>$0.20</span>-<span>$0.50</span>, and almost all of that cost was from the output tokens. The model wanted to use about 750 tokens on each call. I tried to get it to use fewer output tokens by asking it to be brief in my prompt but it made no difference.

I naively forgot this learning during assignment 4 and in a single run I added 4 new features (repo map, interface check, build gate, delay 2nd attempt). The new version solved 20/25 in 137 mins. Prior to this change, the previous version had solved 24/25 in 79 mins.

My takeaway is that it's hard to delete code that you've worked hard on. It might've taken a long time to write and every part of you wants to preserve your work but if something doesn't work after repeated experiments, throw it out. It's that simple.

## 2. Always examine the results of your runs

In assignment 4, when I first submitted for grading, it only solved 3/26. The issue was not that anything wasn't working. Rather, I found that API calls on the leaderboard took 1-2 minutes, 2-3x as long as they did on my own server. As a result, my 40 minute time budgets for each phase meant that I was cutting my first pass after only ~25 calls. The time budgets were something I had set from measuring locally.

In assignment 5, I made a similar mistake by bounding the size of the replies by feel. I set it to 8000, and sometimes the model would take the full 8000 tokens to reason. After measuring, I found that most reasoning was much smaller. I set a limit of 6000 characters for reasoning, which was about the 98th percentile (the median was only 222 characters!). Prior to setting this, 29% of my thinking time was spent on these long reasoning replies.

On the flipside, make sure things that do work aren't set badly. The biggest improvement in assignment 4 came from compacting the conversation at 100k characters. This made my API calls 3x as fast and meant that 88% of prompt tokens were served from the cache. My local run with this compacting solved 19/25 in 73 minutes. However, I later thought that I had set my limit too high. At 75k characters, the conversation was shorter but the agent did slightly worse (17/25 in 83 minutes). And when I lowered it all the way to 17k tokens, three of the tasks resulted in no edits after 130 turns, as I think the agent was forgetting what it was reading. I found this threshold by going too far and having to backpedal back to what was working.

## 3. Your harness NEEDS to Generalize

For anyone reading this, you need to make sure you're not overfitting to training tasks. I ran 25 starter tasks locally and had 26 hidden tasks that I got graded on. Over 2 days I got the local task number up from 13/25 to 24/25. My first 8 grades on the hidden tasks were 3, 9, 12, 8, 10, 11, 11, 10. The best grade on the hidden tasks came from a relatively early version that didn't have much tweaking. The version that was best locally performed worse on the hidden tasks. One clear example was when I tried "fresh restart" for the expert model. This seemed to save lots of time for free locally, but actually tanked my leaderboard score from 12 to 8, because each first pass on the leaderboard took 40-60 min and so when the agent decided to do a fresh restart there wasn't much time left. I realised after the first few runs that I was fitting on the 25 tasks.

The agent did a similar thing in assignment 5, where it decided that the best thing to do was mark the task as completed. It did this by "checking" its work, which involved running a test file. However, it ran the test file as a normal script instead of a test, so it didn't actually run anything. I tried to fix this by introducing a reviewer (the same model in a fresh conversation) that could make edits, but then the reviewer wrote its own test which was wrong, and then changed the original (correct) solution to match its (wrong) test. I subsequently limited the reviewer to only making reports (no edits), and let the original conversation make the edits.

Finally, I fitted on my own run on the last night of the assignment. My first grade on assignment 5 was a run that solved 30/89 tasks in Terminal-Bench in 1h 52m, which was just enough to beat the baseline. I noted that the 30 solved tasks had taken 3.6 task hours while the 59 unsolved tasks had taken 18.8 task hours. I thought to myself that I could easily get a run that solved 25 tasks in 55 mins by doing a second run. After 10 minutes of thinking I realised that I had forgotten to look at the leaderboard chart, and someone was already ahead of me with a run that solved 42 tasks in 9 mins.

I learned to be careful with things that seem to work locally. It seems like knowing how much time to spend on each task is still a useful thing to know, but I can't exploit it in a way that will help me beat the best leaderboard entry. This is why I think having a generalizable harness is imperative in these kinds of experiments.

## 4. Check, Check, and Check your Code

I made a lot of naive mistakes that have helped me become a better programmer. I lost a GPU job that I forgot about because it hit the 4h limit while I was debugging a run on it. I forgot to sync code changes before running and wasted time running on stale code.

None of these are particularly relevant to agents but still I learned to be more careful about checking job time remaining, checking that code was correct before running, and not messing around with scripts while a run was running.

If I had learned more of these things at the start of the competition, it would have made my life a lot easier. In particular, if I had learned #1 earlier I would have saved >1 week of messing around with the harness. After assignment 2 I thought that the way to make better agents was to build better harnesses. Now I think the way to make better agents is to empirically measure what works and carefully change one thing at a time.

## AI use

I used AI to help me check the formatting of the Markdown and manage this codebase.
