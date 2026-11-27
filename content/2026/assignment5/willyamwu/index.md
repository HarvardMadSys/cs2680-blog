---
title: "My Learnings from the past several assignments"
date: 2026-11-25
authors: ["William Wu"]
summary: "Running fewer concurrent tasks made model calls faster but could make the full run longer. Checks may also exit without running the tests they are supposed to run."
tags: ["agent-design", "testing", "llm-serving"]
draft: false
# cover: "cover.webp"   # optional: a figure to show on the listing
---

One thing that I experimented with was trying to make the model call faster. I cut the number of tasks running at once from 25 to 12. As a result, the median model call went from 21.1 seconds to 2.4 seconds. The whole run went from 41.8 minutes to 49.3 minutes. It also solved two more tasks with five new tasks succeeding and three new tasks failing. In addition, I learned how I can use a baseline to help an agent fix a regression, how the retries I used rarely improved results, and how a check can be marked as done without verifying specific important results.

<!--more-->

These were things that I implemented throughout the Assignments. I first built the harness which helped the model run its tools, schedule the work, and decide when a task is finished. As the harness changed, a key aspect was determining whether the changes were leading to the improvement or the failure I was witnessing.

## Determining the Baseline to Find Failures

In the second assignment, the agent was working on a bug for `tomlkit`. The dotted key with a table could be written under the wrong TOML header. This first patch did not pass any of the four checks for the fix. To gather more information about this problem, I utilized the `run_baseline` tool that stashes the edits and then runs the command on the original code, and then restores the edits. I then made the harness report the new failed tests after the edits. I also modified the prompt to investigate regressions. Under this, the feedback showed that there was an edit that was creating unwanted leading newlines. The agent then looked at the failure and revised the placement of the table and white space. This resulted in the later patches being able to pass the four checks and the other existing checks. Ultimately, I changed the harness and prompt together and could see directly how the agent was using a specific regression to guide the next edit.

## Retries Testing Different Ideas

In the third assignment, I tried exploring the issue of working on a problem that had already failed with grading. I had previously added a check where when a patch had failed, the solver would go back again to be able to try again when it has the time and budget to be able to do so. However, in one of the experiments, only one of the nineteen retries was actually successful, signaling that this methodology was not an efficient solution. I later tried to have the solver try a different interpretation of the requirement and make a small change to test it. I also told it to keep the change if the number of failing tests reduced. I also tried to spend more on using the expert review. The standard model did exploration, editing, and testing, and the expert model helped to drive it from the start. I also thought that a second expert pass may help with accuracy. The solver went from zero solves in 11 runs to two solves in three runs with an initial expert reading. However, a later patch gave a different result. It also solved 11 of 26 tasks with or without the reviewer. The runs with review cost $2.63–$3.38 and $1.75 without it.

The expert reviews were costly, and ultimately, I discovered that using the expert model for steering and review did not prove to be fruitful for the leaderboard.

## Using Faster Calls

In Assignment 4, I was able to see how the average call was using ~32,000 input tokens and ~280 output tokens. This meant that across the 25 agents, we would run out of cache capacity fairly quickly. This resulted in a lot of misses as only 6% of the prompt tokens were being reused (minutes 5-25) and there was an average of roughly 31 seconds in the queue. For the full baseline, the token reuse was closer to 49% and the mean queue wait time was ~14 seconds. 

These statistics helped me to notice that the main issue was during the middle where it would get fairly congested. When I decided to use the shared prefixes, I saw the reuse rising to 31%. 

I then tried to raise the soft cap to have more time. This cap raise helped to reach 14/25 solves in 51 minutes. However, since this was just tested on one run, it is difficult to determine if raising the cap will solely contribute to better performance.

I also switched to only 12 concurrent tasks rather than 25 which helped to raise cache reuse from 49% to 90%. Once the task got assigned to a worker, the median solve time went from 26 minutes to 13 minutes. However, the overall time it took to solve these problems increased to 49 minutes.

## Beyond Successful Commands

In Assignment 5, I submitted a pytest file for a check and ran it with `python`. The command exited with zero but had not run any tests. I made the harness run the `check_command` before sending `done`. This sends `done` back if the check is missing, fails, or uses a shortcut such as `|| true` or `exit 0`. The first time a check exits zero without printing anything, the harness asks the agent for a check that shows what it verified.

Another issue was found when the agent saw that the output was the right shape and allowed incorrect values to get through. Something I could improve upon is using a stronger check that would compare the values against an expected result on an input small enough to reason through.

If I were to revise this more, I would try to decide what evidence is needed at each step. I want to ensure that an edit is actually what has passed through and that a new hypothesis is actually tested on a retry. I would also want to check if the results were wrong in the most likely way.

## AI use

I used Claude to review my course notes, run results, and code for this post. I then turned those insights into this blog post in combination with the PR reviewer.
