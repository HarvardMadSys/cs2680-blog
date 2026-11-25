---
title: "I spent more time finding out if the Agent got better than making it better"
date: 2026-11-25
authors: ["Jiayi Cora Guo"]
summary: "I spent the most time on changing prompts, and I got the least out of it. I spent the least time on measuring run time and making the server better, and I got the most out of it."
tags: ["observability", "testing", "agent-design"]
draft: false
toc: true
---

I spent the most time on changing prompts, and I got the least out of it. I spent the least time on measuring run time and making the server better, and I got the most out of it.

<!--more-->

## 1. The same file gives different scores

I thought the same code would get the same score if I submitted it twice.

In A4 I took the ZIP file with the best score and submitted it again. I did not change anything. Submission 9 got 12/26. Submission 14 got 6/26.

The model does not give the same output every time, so the score itself moves. I knew this. But before I saw these two numbers, I did not treat it as something I had to measure first.

Next time: Before I change anything, run the same version twice and see how much the score moves on its own.

## 2. One run is not enough to see a small improvement

On the leaderboard, the standard deviation of my score was about 2 tasks, in both A3 and A4.

In A3 I did a rough calculation. To see a difference of 0.5 tasks, I need about 200 runs per version. If the difference is 1.5 tasks, about 20 runs is enough.

And the number of runs I could pay for was less than ten. So for any change with an expected gain under one task, I could not tell if I had made it or not. I only did this calculation after I had changed the prompt many times.

Next time: Before starting an experiment, work out how many runs it needs. If the answer is 200 and I can only pay for 2, I should not do the experiment.

## 3. Which tasks keep changing?

In A5 I ran 89 tasks on my own machine. Two runs were only 4 tasks apart in total score. I thought this meant only 4 tasks changed.

16 tasks changed. 10 tasks that passed before failed, and 6 tasks that failed before passed. After they cancel out, only 4 are left.

In A4 I put the tasks into three groups by pass rate: the ones that almost always pass, the ones that almost never pass, and the ones that pass about half the time. Almost all of the score movement comes from the third group. The first two groups give the same result no matter how many times I run them.

Next time: Compare task by task, not just the total score. And for a task that keeps failing, running the same version again usually does not help.

## 4. Change one thing at a time

In A4, one night I submitted seven changes together. The submission before that got 8/26. This one got 4/26.

And I still do not know which of the seven did it. More runs would only tell me this version is worse. They would not tell me which change is worse.

Next time: When I only have a few submissions, use one submission to answer one question.

## 5. The expected gain was smaller than the noise

In A5 I asked the AI to estimate how much each prompt idea would help. The best one was worth about one more task.

And the same code on Terminal-Bench, 89 tasks, often gives two scores that are 3 tasks apart.

So I could not check any of these ideas. I still made some of them, because changing a prompt is cheap. But I should not count them as improvements. The things that really showed an effect were changing the server and changing how the time was used.

Next time: When runs are limited, only make changes with an expected effect larger than two times the noise.

## 6. Give the model one specific fact

In A2, 10 tasks on my own machine. First I added a general instruction: check your own work before you finish. The score went from 6/10 to 5/10.

I thought the instruction made things worse. Then I read the log. The task I lost was a random failure on the OpenLibrary side, and it had nothing to do with the instruction.

The change that really helped came later. I put one specific sentence into the check message: “The six files in this folder all use export default, and your file does not.” The protonmail task failed three times in a row before this, and passed two times in a row after it.

I think telling the model to be careful, and telling the model where it is wrong, are two different things.

Next time: Let the harness find the problems the model cannot see, and then tell the model the problem directly.

## 7. More prompts and more checklists did not help much

In A3, on my own machine, I tried three things: put past lessons into the prompt, add a checklist, and give the agent more budget.

The lessons run used a smaller set of 8 tasks, and 7/8 became 6/8. The checklist run used 26 tasks, 11/26 became 10/26, and the run took 22% longer. The budget run also used 26 tasks, 11/26 became 14/26, and the cost went up 36%.

And each of these ran only once. With the standard deviation above, none of these numbers means anything. The +3 from the budget run is close to two standard deviations, but I paid for it with cost, so I cannot count it as an effect of the prompt.

In A5 I tested a checklist again on its own. I thought the model was skipping the checklist. In the logs of 33 single-task runs, it read the checklist every time, and it never changed the code after reading it.

Next time: After adding a feature, read the logs first and see if it really changed what the agent does. If the model read something, that does not mean it did anything because of it.

## 8. It is not enough when the Agent says it is done

In A2 there were three times when the agent reported a fix, and nothing in the repository was fixed.

One time it searched for a string and counted that as a pass, without running the code. One time it wrote a test based on its own wrong guess, and of course the test passed. And one time it ran the test after git stash, so it tested the code from before the change.

What these three have in common is that the word “pass” came from the agent itself.

Next time: Let the harness check. Really run the code, do not search for text. And use the real grader whenever I can.

## 9. Check if a feature is really running

In all four assignments, there was at least one feature that was written but not running.

In A3 a parser only found 8 tasks out of 414. In A4 a switch that should have turned off retries did not work. In A4 the temperature was never set. In A2 a counter counted the wrong thing.

And none of these four gave an error. In some of them the condition was never met, and in some the name was wrong. The program still finished, and the log still came out.

I thought problems like this would show up on their own while I was debugging. They do not, because “it did not happen” and “it happened but the result is the same” look the same in the output.

Next time: Write one log line every time a feature runs, and count how many times it ran. If the count is zero, then the version I tested is the same as a version without the feature.

## 10. Measure where the time goes first

In the first full run of A4 on my own machine, I split the time up: about 90% waiting for the model, 7% on tool calls, 3% on grading.

And in another run of the same assignment, that 90% can be split again: about 72% goes to generating tokens.

One level further down, calls that output more than 2,000 tokens are only 8% of all calls, and they take 40% of the time.

Next time: Find the biggest part first, then find the few slowest calls inside that part. I think these are worth more than the average call.

## 11. The server needs enough room for tasks that run at the same time

In A4, on my own machine, with thinking turned off, I started all the tasks at the same time. The cache hit rate went from 96% to 6%, and the calls per minute went from 148 to 17.

The cache on the server could not hold that many conversations, so it started to delete tokens it had cached before. When the next call came, those tokens had to be computed again, and then they were replaced again by later conversations.

I thought the problem was that I was not running enough tasks at the same time. In fact I was already running more than the cache could hold. The extra tasks were slow themselves, and they also made the other tasks slow.

Next time: Estimate how many conversations the cache can hold at the same time. A rough upper limit is the cache size divided by the average conversation length. And watch the cache hit rate, not just how many tasks are running.

## 12. More tasks at the same time does not always mean faster

In A5 on my own machine I compared two settings: 26 tasks at the same time, and 12 tasks at the same time.

I doubled it, and the total throughput only went up 15%. But each task took 1.8 times as long.

When the GPU is close to its limit for generating tokens, adding more tasks only means more tasks share the same ability.

Next time: When throughput stops going up, stop adding tasks. And measure how long it takes to finish everything, not how many tasks are running at the same time.

## 13. One slow command can slow down the whole run

I said above that tool calls were only 7% of the time in that A4 run, so for a while I stopped looking at tool calls.

And in one A3 run on my own machine, a single task spent 1,288 seconds on 26 Go commands. In that run, tool calls were 33% of the total time.

7% is an average, and 33% is an average too. The difference is whether that one task is in there. An average cannot tell me if a task like that exists.

The agent also sometimes sets a timeout that is too short for a build. The build gets killed, it tries again, and the time is gone.

Next time: Look at the slowest tasks and the slowest commands. And do the work I can predict, like builds, downloads and installing dependencies, before the real run starts.

## 14. The patch sent to the grader is not what the Agent changed

Between A2 and A3, I had five problems with just exporting the patch.

Changes that were already staged did not go in. When a file was renamed, the delete of the old file was not written into the diff. A 55 MB build output went into a patch. A placeholder PNG made the patch fail to apply. And a Redis dump file went into another patch.

I thought that if the local evaluation used the exported diff, this step would be fine. The local evaluation did use the exported diff. But I never checked if that diff had the changes it should have.

If the agent made the right change and the grader did not get it, the score is the same as getting the task wrong.

Next time: Test every step between the agent and the grader on its own. Renames, deletes, staged changes and binary files all need a test.

## 15. If code can stop it, do not only write it in the Prompt

In A2 I had one rule: the agent must not change the tests.

I did not only write it in the prompt. I used code to stop writes to the test files, I put the original tests back at the end of the run, and I deleted the test files the agent created.

And the agent still tried to change the tests. The changes were rolled back, and that task still passed at round 88.

A rule in the prompt needs the model to remember it. A rule in the code does not.

There is a related example in A5. I designed an approval file that only I should create. What I did not think about is that the AI could create that file itself. An approval the AI can create itself is not an approval.

Next time: If something must never happen, use code to stop it.

## 16. Saying yes in the chat does not change the permissions

In A4, one night I told the AI: “I am going to sleep, you can auto-approve.” And then I went to sleep.

At 1:31 in the morning a command came up and waited for approval. It waited until I got up at ten. Nothing ran for eight and a half hours.

Permissions live in the config file and in the tool layer, not in the chat, and what I say in the chat box cannot change them. It also did not tell me this. I only found out the next morning when I read the log.

Next time: Set permissions where the system can read them. And before leaving a long task alone, check that the permissions really work.

## 17. I did not write the code, but my questions changed the result

From A2 to A5, the AI wrote almost all of the code, ran most of the experiments, and made most of the submissions.

And the three things that really changed the result all started from a question I asked. In A2 I asked to run the evaluation again on the exact code I had submitted. In A3 I asked why one leaderboard run was estimated at 8.30 dollars. In A5 I did not agree to let the machine run for another 40 hours while it was doing nothing.

The AI did not bring up any of these three. It is very good at finishing the task I give it. But it does not ask if the task is worth doing.

Next time: I think my main job is to ask if the assumptions are right, and to know when to stop. These are the questions I ask the most:

- Under what conditions was this number measured?
- How much time and money does this cost?
- Why do you think this will work?

## 18. Read all of the code copied from an earlier project

In A5 I used a regular expression to scan the code I brought over from the older assignments. It found 59 matches in 9 files. I thought that counted as checking it.

The most important problem was not in those 59 matches. I found it later by reading the code line by line. A regular expression can only find the pattern I already know I am looking for, and it cannot find the thing I forgot to look for.

In the same round I also replaced the old agent, about 3,700 lines, with a new one of about 600 lines. The new one got Terminal-Bench 36/89 on its first submission, which was a passing score.

Next time: Use a scan to cover many files, and read the code to know what it does. If a file is already big and most of the code in it is not needed any more, rewriting it is usually easier than adding more patches.

## 19. My check only checked the things I had thought of

In A4 I added a check, and it covered the recent changes.

The code that caused the problem was copied from A3. It was not in the recent changes, and it did not contain any of the repository names I searched for. It missed both conditions.

I designed the check from “what did I change recently”. I should have designed it from “what do I want to stop”.

Next time: Put the code I copied from before inside the check too. It is the easiest thing to miss, because it was already there before the check existed.

## AI use

I wrote the entire piece in Chinese and used AI to translate it. I also used AI to check the accuracy of what I had written. Claude Code put the text into the blog template and opened this pull request.
