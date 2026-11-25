---
title: "What I Learned from Building a Coding Agent"
date: 2026-11-25
authors: ["Justin Liu"]
summary: "Across our assignments 2-5, I learned that improving an agent normally begins with checking what it actually did."
tags: ["agent-design", "observability", "serving"]
draft: false
---

Across our assignments 2-5, I learned that improving an agent normally begins with checking what it actually did. In A2, requiring it to run the examples given in each task improved timeutils from 1/5 to 4/5 solved and wraps from 0/3 to 3/3. Those examples caught real mistakes, like returning a date without the required timezone.

<!--more-->

Sometimes, though, a simple setting helped more than adding code. In A3, turning off reasoning kept 14 solves while reducing cost per solve from <span>$0.136</span> to <span>$0.084</span>. I wish I had tried this sooner, but you could also argue it was a lucky draw among countless other possible optimizations.

As I worked through the assignments, I also became more cautious about noise and interpreting scores. The same code had solved 14 then 10 tasks in A3, and the same setting solved 26 then 30 in A5. With so much variance, it was at times discouraging/hard to attribute every small increase as evidence that a change I made had worked.

In A4, comparing server logs with agent timings showed that a GPU over 90% busy was repeatedly processing discarded conversation history. Keeping that history in CPU memory and prioritizing cached requests helped me cut average turn time from 100.5 to 22.3 seconds. This was useful in understanding where the work was going instead of just relying on GPU utilization.

I thought it was interesting how logs also revealed failures that scores alone couldn’t explain. In A5, one task repeated a command about 150 times because my stuck check only counted failed commands. After fixes, model calls averaged 5.6 rather than 7.4 seconds, although solves barely changed.

Finally, it's worth noting that more time didn’t always produce better results. Tighter task limits shortened an A5 run from 82 to 45 minutes with the same 30 solves. But an earlier A4 cutoff reduced solves to 5/26 instead of 8-10, so I learned to check when successful tasks finish before shortening their budgets.

## AI use

Claude was used to help run experiments, check formatting, and collect/verify measurements.
