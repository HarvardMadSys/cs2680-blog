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

While working on Assignments 3 and 4, I found that I was able to achieve the best performance by creating harnesses with relatively simple designs (for reference, I achieved Rank 1 for both). For Assignment 3, my harness used an expert probe to break down the task into smaller tasks for a more standard model to tackle; for Assignment 4, my harness had access to some language-specific skills and simply ran a single trajectory until the time limit was reached. While there were some more features involved (e.g., repo-specific memory, basic context compaction), everything was relatively simple, and I was surprised by how effective this was.

However, I also noticed that there was a good amount of variance in the harnesses' performances across different submissions with identical code. I figure that this is most likely due to how simple and gentle the harnesses were, in conjunction with the lower intelligence of the models we used. Intuitively, it makes sense to me that smarter models will be able to manage complex harnesses more effectively and get more consistent results i.e., the intelligence of a model and the complexity of its harness should increase proportionally to achieve peak performance.

A lingering question I have is, how much variance does Claude Code itself have?

## Human are Still Vital

At the end of the day, my greatest takeaway is that the Claude Code user is still a vital part to a project's development. As I was working on Assignments 3 and 4, I found that I was the one introducing key features to development while Claude Code was making suggestions that seemed relatively insignificant. The effects of this are probably most easily observed through the fact that students who did most of the steering were able to beat students who used auto-research loops.

I expect this to change in the future, but perhaps us engineers still have substantial purpose in the meantime.

## AI use

I did not use AI at all for this writeup.
