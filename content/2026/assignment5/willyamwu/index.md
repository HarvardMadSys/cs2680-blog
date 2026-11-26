---
title: "My Learnings from the past several assignments"
date: 2026-11-25
authors: ["William Wu"]
summary: "I have spent the past several weeks testing and experimenting to improve a coding agent across several assignments. Here is what I have learned"
tags: ["assigmnent5", "agent-design", "testing", "llm-serving"]
draft: false
# cover: "cover.webp"   # optional: a figure to show on the listing
---

One thing that I experimented with was trying to make the model call faster. On the GPU side of things, I cut the number of tasks running at once from 25 to 12. This allowed the median model call go from 21.1 seconds to 2.4 seconds. The whole run went from 41.8 minutes to 49.3 minutes. It also solved two more tasks.

<!--more-->

These were things that I implemented throughout the Assignments. I first built the harness which helped the model run its tools, schedule the work, and decide when a task is finished. As the harness changed, a key aspect was determining whether the changes were leading to the improvement or the failure I was witnessing.

## Determining the Baseline to Find Failures

In the second assignment, the agent was working on a bug for `tomlkit`. The dotted key with a table could put a wrong entry into the wrong TOML header. This patch did not pass any of the four checks for the fix. To gather more information about this problem, I utilized the `run_baseline` tool that put the edits to the side. I then made the harness report the new failed tests after the edits. I also modified the prompt to investigate regressions. Under this, the feedback showed that there was an edit that was creating unwanted leading newlines. The agent then looked at the failure and revised the placement of the table and white space. This resulted in the later patches in being able to pass the 4 checks and the other existing checks. Ultimately, I changed the harness and prompt together and could see directly how the agent was using a specific regression to guide the next edit.

## Retries Testing Different Ideas

In the third assignment, I tried exploring the issue of working on a problem that had already failed with grading. I had previously added a check where when a patch had failed, the solver would go back again to be able to try again when it has the time and budget to be able to do so. However, in one of the experiments, only one of the nineteen retries were actually successful, signaling that this methodology was not an efficient solution. I later tried to have the solver try a different interpretation of the requirement and make a small change to test it. I also told it to keep the change if the number of failing tests reduced. I also tried to spend more on using the expert review. The standard model did exploration, editing, and testing, and the expert model helped to drive it from the start. I also thought that a second expert pass may help with accuracy. The expert reviews were costly, and ultimately, I discovered that using the expert model for steering and review did not prove to be fruitful for the leaderboard.

## Using Faster Calls

In Assignment 4, I was able to see how the average call was using ~32,000 input tokens and ~280 output tokens. This meant that across the 25 agents, we would run out of cache capacity fairly quickly. This resulted in a lot of misses as the only 6% of the prompt tokens were being reused and there was an average of roughly 32 seconds in the queue. These statistics helped me to notice that the main issue was during the middle where it would get fairly congested. When I decided to use the shared prefixes, I saw the reuse rising to 31%. I then tried to raise the soft cap to have more time. I also switched to only 12 concurrent tasks rather than 25 which helped to raise cache reuse from 49% to 90%. Once the task got assigned to a worker, the median solve time went from 26 minutes to 13 minutes. However, the overall time it took to solve these problems remained roughly the same. 

## Beyond Successful Commands

In the Assignment 5, I needed to go beyond after the agent has called `done`. When I ran a pytest file with plain python, the process exited with code zero and did not end up running the tests. When the harness ran the proposed `check_command` and sent back the silent success. 

Another issue was found when the agent saw that the output was the right shape and incorrect values could get through. A stronger check would compare the values against an expected result on an input small enough to reason through.

If I were to revise this more, I would try to decide what evidence is needed at each step. I want to ensure that an edit is actually what has passed through and that a new hypothesis is actually tested on a retry. I would also want to check if the results were wrong in the most likely way.

## AI use

I used AI to review my course notes, run results, and code for this post.
