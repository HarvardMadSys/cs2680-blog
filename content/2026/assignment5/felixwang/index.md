---
title: "From Runnable to Knowing What’s Effective"
date: 2026-11-23
authors: ["Felix Wang"]
summary: "For each assignment, I always let my Claude Code make the simplest version that is runnable, then iterate from it to reach higher goals. From those processes, here are the most important 4 lessons I took."
tags: ["agent-design", "human-in-the-loop", "evaluation", "serving", "reasoning"]
draft: false
---

This title summarizes the regular process I used across all my assignments this semester, except A1, which was basically one-shot prompted. For each assignment, I always let my Claude Code make the simplest version that is runnable, then iterate from it to reach higher goals. From those processes, here are the most important 4 lessons I took.

<!--more-->

## 1. Let the agent cook, but own the direction

I was ranked top 1 in A3 and in my presentation I said “let Claude cook”, and I tried to push it further in A4 and A5 and apparently that didn’t go as well as expected (admittedly I had less time to spend on A4A5 but still the results were worse than I’d imagined).

On the one side, I still believe granting coding agents enough permission, autonomy, and trust is important. Agents these days are good, really good. And they’re not only good at coding, but also researching, experimenting, and especially systematically collecting and analyzing results. Also, another perk that humans don’t have: they work 24/7. In many scenarios I found being able to utilize these advantages of AI is super important and it’s my secret to be a 10x efficient contributor when I’m working in fast-moving companies. It shapes my workflow, even used till the end of A5.

Below is a graph illustrating my workflow across all the assignments: me and my agent doing research side by side, choosing a few directions and letting my agent build, then test and gather results and conclusions, finally with some human decisions to enter the next cycle.

![Workflow: research, build, controlled A/B tests, human decision, and repeat.](fig1_workflow.svg "My workflow: research, build, test one change, and repeat.")

However, sometimes I found that when working on deep and hard problems, over reliance on my agent could be harmful and inefficient. There were quite a few examples from A4, where I ran many overnight sessions but many times the sessions only explored along one direction or kept iterating on several factors without exploring further. Those overnight sessions might bring the performance higher a bit but tend not to produce very useful information for further improvement, especially if we’re looking for large changes that could improve dramatically.

I think that’s a great lesson telling me the difference between human researchers and AI agents. At the moment I tend to believe agents have relatively fixed context based on the session history and finished research, so experiments initiated by AI are always purely based on that and not creative; whereas humans have very diverse and long thinking history and have way more complex inspiration and ideas. That’s what a lot of people call “taste” in research today, and it’s the first time I feel it’s genuinely so important.

This is the biggest takeaway from the whole semester.

## 2. One good run doesn’t prove much

The second lesson is more straightforward. In the first half of A3, I pretty much never ran one version twice, for the sake of maximizing my daily credit. I don’t remember clearly but actually think it was unintentional the first time I submitted a version twice - might have selected the wrong file - but then observed pretty large differences between the two runs. It was not just accuracy difference but many times it was also about which questions it got right and which it got wrong.

Below are some examples from A3/4/5 showing the total score differences. This graph doesn’t show which individual tasks changed. Names like lean5, lean19, lean24 and lean28 are just labels I used for different harness versions.

![Total tasks solved across repeated runs in A3, A4, and A5.](fig2_repeat_runs.svg "Total scores varied across repeated runs of the same version.")

The first time it happened I was actually blaming the grader infra changes haha. But as I tried more it was pretty obvious that the infra fluctuations are rather minor but there’s always an inherent level of instability and randomness in different versions (e.g. one of my A3 harness versions, called passback, is a good example of high potential but high instability).

That leads to my practice later to freeze each version and experiment with them multiple times, keep good track of the results, separating local ones and online leaderboard, also eventually to the practice to change one thing at a time and don’t stack changes (though I think I have large room to improve there, still not patient enough).

## 3. A good harness depends on the model and hardware

Every time I asked my Claude to migrate An to A(n+1) and make a minimal runnable first attempt, I was expecting a better result but always got a very bad one. That’s where this lesson was mainly from.

For example, in A3 my architecture included 5 independent workers, a cheaper model called Standard trying first, a more expensive model called Expert for reviewing/assisting, and fresh retries. Apparently that got a pretty good result. But when the same harness directly migrated to A4, with now fixed model and one shared GPU, the minimal migrated first version only got 1/26 on the leaderboard. That’s a different set from the 25 public tasks used for the local A4 runs in Fig. 2.

Below is a chart showing the serving benchmark: the same 477 requests, from 25 real agent conversations.

![Runtime: 660 seconds at 25 concurrent sessions, 299 at 12, and 356 at 25 with host caching.](fig3_serving_bench.svg "The same workload finished faster with lower concurrency or host caching.")

In this benchmark, fewer concurrent sessions or host caching made the same workload finish faster. But I only ran each setting once, so I’d need repeats to know how consistent that difference is.

## 4. Faster actions don’t always mean faster solves

Seeing many classmates benefit from no-thinking mode, I was making the same assumption: no-thinking means faster actions and could lead to more solves.

That wasn’t what I saw in one paired local run in A4. I compared two versions on the same 13 public tasks: lean66 used adaptive thinking, meaning it only turned thinking on at certain decision points, and lean68 had thinking off throughout. Everything else was the same. Results are below:

![Solve curves for 13 tasks: adaptive thinking leads most of the run, with both reaching 10 by 60 minutes.](fig4_thinking_pair.svg "Adaptive thinking reached 10 solves earlier; no thinking caught up by 60 minutes.")

In this run, adaptive thinking reached 10 solves earlier, though both got 10/13 by 60 minutes. My guess is that extra mistakes and retries could eat up the time saved by shorter replies, but the solve curves alone don’t tell us that. And this was only one paired run, so I’d need repeats before saying which works better overall. Again this doesn’t mean no-thinking is absolutely a bad choice. I believe it highly depends on the overall harness design and structure. I see this as a reinforcement of lesson 3 and also showing that harness design is not simply adding things up, many designs are synergistic and influence the performance collectively. While lesson 2 suggests the importance of controlled experiment, this means sometimes synergistic experiments are also necessary and can lead to new findings.

Of course throughout the whole semester I learnt more than these but the above 4 lessons are the most major takeaways and conclude the class nicely for myself. It was an amazing learning journey.

## AI use

I wrote the blog text myself. Claude Code helped create the figures, format the post, and open the pull request. All data come from my actual assignment results.
