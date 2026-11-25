---
title: "Trial and Error in CS2680"
date: 2026-11-24
authors: ["Sam Gallaudet"]
summary: "I learned the power and limitations of agentic systems and developed better practices for working with agentic AI."
tags: ["agent-design", "testing", "observability, user-feedback"]
draft: false
# cover: "cover.webp"   # optional: a figure to show on the listing
---

Over the course of Assignments 2 through 5 I learned how to use AI more effectively when coding through a number of mistakes and corrections. 
<!--more-->

## Early success led to overconfidence

In the first assignment I was a bit dazzled by how effective Claude Code could be. It was
very capable of making a local server and displaying the different requested aspects on the
frontend. The only struggle was clearly communicating certain design goals, but with more
detailed prompts I was able to get exactly the frontend I wanted. Ironically, the capability
of Claude in the first assignment led me into pitfalls in the later ones. I went into
Assignments 2 and 3 in particular overestimating Claude's abilities.

## Make the agent show evidence

In Assignment 2 I blindly trusted Claude too often. One example was when Claude reported
that task 9 had failed, likely because the tests did not run. I accepted this, but later on
when working on the assignment I discovered that the tests did run, and the reason task 9
failed was due to how a function was exported.

These issues also showed up in Assignment 3. I implemented changes that Claude suggested
with little testing and just trusted that whatever it suggested would lead to a more
effective harness. This led to haphazard leaderboard submissions that often did not improve.

What I learned from these errors was that in order to use Claude more effectively I need to
have it provide actual evidence to back up its claims. Ideally I should have that evidence
in mind instead of letting Claude measure itself. For example, I could have had Claude
return the output from task 9, or when making the harness in Assignment 3 I could have asked
specifically how many tokens and API calls were made in test runs.

## Keep track of what changed

I also struggled to keep track of what Claude actually did. For the Assignment 2 "solved
after changes" tasks, I had to ask Claude several times what the changes it made actually
were, because I had forgotten. In Assignment 3 I lost track of the changes I made to the
harness as well, which made it more difficult to undo harmful changes or understand what I
should try next. To keep track of what Claude has done, I could have had it create a log
that it would consistently update as it made changes.

## Change one thing at a time

Assignment 3 was a big step up from the first two assignments. As a result I both made a
lot more mistakes and learned a lot more from it. In Assignment 3 I learned the dangers of
changing multiple things at once. I had Claude make many changes at once because I figured
that any suggestion from Claude would likely help my harness. However, my first few
leaderboard submissions decreased in quality, from 13 to 10 to 8. The changes I made hurt
my leaderboard score, and because I made them all at once I could not determine the direct
cause, so the submissions were fully wasted and I didn't learn anything from them.

## One local run is not evidence

Even when I did try to test changes, I typically just tested them using one test run on the
5 local images. This was not helpful, because getting 3 out of 5 solves vs. 4 out of 5 is
within the bounds of a noisy run, and you cannot deduce from just one run that a harness
change is actually more effective.

In addition, the local tasks are not the same as the leaderboard tasks, so even if I were to
test multiple times and find a change effective locally, I shouldn't assume that it will be
effective on the leaderboard as well. Some of my best local runs led to poor leaderboard runs
that underperformed earlier harnesses that had actually done worse on the local images.
Reading too much into local runs both caused me to attribute effectiveness to changes when
there wasn't any evidence for it, and made me overtune my harness to the local tasks, making
the leaderboard submissions worse.

## Applying the lessons

In the later assignments I applied these lessons. I changed things one at a time, and pushed
Claude to explain its reasoning for each change instead of just blindly accepting it. In
Assignment 4 I kept a log of every change so that I wouldn't lose track of my harness or
engine at any point. I also didn't take performance on local runs as a guarantee that a
submission would improve. Because of this more careful approach, I could test a change
locally to see if it was worth trying on the leaderboard, then submit. If it succeeded I
would mark it down, and if it failed I could easily revert to the previous state.

My main takeaway is that Claude is much more powerful when the user has a clear idea of the
goal, how to test it, and what changes are being made. Properly using agentic systems has a
much higher skill ceiling than I originally thought, and one cannot do good work assisted by
AI without a great deal of thought.

## AI use

I wrote this blog post myself. I used Claude Code to reformat it when I pasted it from google docs to the markdown file. Claude created section delineators when it reformatted which I kept. It also fixed typos and added several tags which I also kept. 
