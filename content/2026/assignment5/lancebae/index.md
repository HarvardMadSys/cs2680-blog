---
title: "What I've Learned from COMPSCI 2680"
date: 2026-11-24
authors: ["Lance Bae"]
summary: "COMPSCI 2680 was my first real experience using Claude Code and building agent harnesses, and I've learned a lot!"
tags: ["claude-code", "agent-design", "context-management"]
draft: false
---

In this post, I'll talk about the key lessons I've learned when working with and building coding agents: (1) how to effectively manage agent sessions and memory; (2) simple harnesses worked best for our assignments; (3) human reasoning is still needed for Claude Code.

## Managing Claude Code Sessions

As I worked on Assignment 2, I thought that the easiest way to do so was by having one (or a few) very long Claude Code session(s). This way, I didn't have to constantly re-contextualize my agent on what we were working on, how the codebase was structured, etc... However, once I started working on Assignment 3 (and learned in class about better ways to manage agent memory), I switched up my approach.

Starting with Assignment 3, I realized how useful it was to have a good CLAUDE.md file, and I switched to having more sessions that were shorter. In CLAUDE.md, I could give my agent sufficient context about what I was working on without having to keep one long session running. Since Assignment 3 (and also Assignments 4 and 5) required constant iteration on results, I also had Claude version its commits (each commit message included which version it was e.g., Version 3.1.4) and manage a HISTORY.md file that detailed what each version introduced and how it did when submitted to the online leaderboard. This versioning and written history made it much easier to inform Claude on what we had tried in the past and how effective each new feature was. I could also use the versioning to very easily backtrack to a previous iteration if new features seemed to do more harm than good.

I could see as I worked on Assignment 3 and onwards that having shorter sessions was better. Since sessions are independent, I could rely on Claude having a relatively fresh approach to each new prompt rather than being influenced by something that it had said or recommended previously in its trajectory. Context compaction can also be a black box when working with long sessions, as you might not know what details are retained or lost; this is undesirable. Shorter sessions also mean shorter trajectories i.e., fewer tokens having to be processed, which will result in cheaper work (though this was never a serious issue given how generous my limits were).

## On Harness Design

While working on Assignments 3 and 4, I found that I was able to achieve the best performance by creating harnesses with relatively simple designs. For reference, I achieved Rank 1 in both.

For Assignment 3, my harness used an expert probe to break down the task into smaller tasks for a more standard model to tackle. While I acknowledge this is a non-trivial design, I'd consider it to still be relatively simple and accessible, as it's very similar to Claude Code's subagent structure which was covered in class. This scored 19/26, <span>$</span>0.4544, 8:04 on the online leaderboard. Notably, a later design that gave the probe the option to solve the task on its own was Pareto-dominated (15/26, <span>$</span>0.5509, 9:53) by this forced subagent system!

For Assignment 4, I attempted to reuse my Assignment 3 harness to not much success, likely because there was no longer an especially smart model that we could access; we only solved 8/26. I decided to simplify the harness, running a single trajectory until the time limit was reached. While there were some more features involved (e.g., cross-task per-repo memory), I didn't have to reach for anything outside of what was covered in class, and I was surprised by how effective they were, ending up with a score of 18/26.

An important note here is that there was a good amount of variance in the harnesses' performances across different submissions with identical code. For example, the aforementioned 19/<span>$</span>0.4544/8:04 harness for Assignment 3 also scored 12/<span>$</span>0.7283/13:36 when I resubmitted it. I figure that variance emerges due to how simple and gentle my harnesses were, in conjunction with the lower intelligence of the models we used. For reference, a harness version I created later on was much more robust (larger time and turn budgets), and its results were much more stable:

| Submission | Solved | Cost / solved | Time / solved |
|---|---|---|---|
| 4.8 | 18/26 | \$0.4708 | 8:48 |
| 4.8r1 | 16/26 | \$0.5301 | 14:01 |
| 4.8r2 | 19/26 | \$0.4377 | 9:50 | 14:44:29 |
| 4.8r3 | 19/26 | \$0.4387 | 9:49 |

Intuitively, it makes sense to me that smarter models will be able to manage complex harnesses more effectively and get more consistent results i.e., the intelligence of a model and the complexity of its harness should increase proportionally to achieve peak performance. A lingering question I have is, how much variance does Claude Code itself have?

## Human Are Still Vital

At the end of the day, my greatest takeaway is that the Claude Code user is still a vital part of a project's development.

As I was working on Assignments 3 and 4, I found that I was the one introducing key features to development while Claude Code was making suggestions that seemed relatively insignificant. For example, I was the one who thought to include features like cross-task per-repo memory, full context compaction, and per-language skills, all of which were very important to my Assignment 4 success. Meanwhile, Claude Code was suggesting things like only compressing tool outputs (instead of the entire trajectory) and tweaking config numbers.

I think that the greatest pieces of evidence in support of my argument are the results of Assignment 3. We were told in the feedback presentation that there were some students who had opted for auto-research loops with Claude Code, yet most of the Rank 1 students who presented on their designs seemed to have done a lot of manual thinking and reasoning. The fact that Rank 1 was not full of students who had used auto-research assured me that us engineers still have substantial purpose at least for a little longer.

## AI use

I used AI to help me resolve some formatting desires in this post (e.g., the Markdown table), but all of the prose was written by me.
