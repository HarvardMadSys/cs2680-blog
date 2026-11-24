---
title: "What I Learned by Measuring the System Around a Coding Agent"
date: 2026-11-24
authors: ["Ebenezer Tseh"]
summary: "Lessons from Assignments 2–5 on patch capture, model handoffs, GPU caching, and recovering from truncated responses."
tags: ["agents", "inference", "evaluation"]
draft: false
---

Across Assignments 2–5, I worked on getting a coding agent to solve more tasks within limited time and cost budgets. That involved building the agent loop, deciding when to use a more expensive model, running a model server, and diagnosing why tasks failed.

A number of helpful observations were made in the course of exploring the context around the model, including how edits were turned into a submitted patch, how conversations involved sharing GPU memory, and what actions the agent took following an incomplete answer. These assignments taught me to distinguish between getting a change to work, making the system faster, and improving task success. They also taught me to check whether a higher score was actually due to the change.

## 1. Check that the agent’s work actually reaches the evaluator

In Assignment 2, I built a coding-agent loop that could inspect a repository, edit files, run commands, and produce a patch. One failure came from the final step.

On a local task, the patch-capture pipeline omitted two deleted files. The working directory contained the intended changes, but the submitted patch did not represent the complete result. All three previously failing tests still failed when evaluating that patch. After changing the capture step to use `git diff HEAD`, all three passed.

The relevant distinction was between comparing the working tree with the staging area and comparing the current changes with `HEAD`. Looking only at the former can miss changes already represented in the staging area. The problem was in my patch pipeline, not evidence that Git generally ignores deleted files.

This changed what I considered necessary to verify. Checking the files left by an agent was insufficient: I also needed to inspect the artifact that would actually be evaluated.

Another task exposed a different limitation. With a 50-iteration budget, the agent ran out of turns before completing verification. A later configuration with 80 iterations, a checkpoint, and a warning passed all three previously failing tests. That experiment changed several things together, so it did not isolate the effect of the larger budget. It did show why the reason for stopping matters.

The lesson was to trace a failure through the complete process: the model’s response, tool execution, resulting files, submitted artifact, and evaluation. Improving the model’s instructions would not have repaired a missing deletion in the patch.

## 2. A more expensive model needs a useful handoff

Assignment 3 added a monetary budget and different model tiers. This made model selection part of the agent’s design.

My final approach used Standard for the initial attempt and selectively called Expert for a repair. Standard had up to 100 turns. An eligible repair received up to 40 Expert turns, starting from a fresh conversation with a bounded handoff.

I compared that approach with retaining the full conversation and with two versions of masked history.

| Repair context | Tasks solved | Cost per solve | Seconds per solve |
| --- | --- | --- | --- |
| Fresh handoff | 4/5 | $0.2692 | 419 |
| Full history | 4/5 | $0.3674 | 520 |
| Masked history, version 1 | 3/5 | $0.5189 | 902 |
| Masked history, version 2 | 3/5 | $0.4626 | 1,124 |

*These were individual local runs. The repair phases started from different Standard-generated patches, so this was not a controlled comparison of context alone.*

The fresh-handoff run had the lowest measured cost per solve. Two of its four solved tasks were rescued during Expert repair, but Expert still accounted for 87.8% of the run’s spending. Selective use did not make Expert cheap; it concentrated the expense.

Not every attempt to involve another model helped. An advisor approach produced no rescues across seven consultations. Adding another consultation created more work without demonstrating a benefit in those trials.

My takeaway was that the handoff deserves as much attention as the model choice. The repair model needs enough information to understand the current state and remaining problem. A long conversation also contains abandoned approaches and observations that may no longer matter. More history is something to evaluate, not an automatic advantage.

## 3. More workers can mean less useful parallelism

In Assignment 4, I moved from a course-hosted API to serving the model myself. The agent and the server now had to be considered together.

I began with 25 workers. In the measured baseline run, the agent solved 11 of 25 tasks in 99.9 minutes. Eight model requests hit a 600-second timeout, and four tasks produced empty patches. Average prompts were around 41,000 tokens.

Reducing the worker count to eight produced a substantially different local run:

| Measurement | 25 workers | 8 workers |
| --- | --- | --- |
| Solved tasks | 11/25 | 19/25 |
| End-to-end time | 99.9 min | 61.0 min |
| Cache reuse from token counters | 30.8% | 94.7% |
| Evicted tokens | 38.84 million | 2.75 million |
| 600-second request timeouts | 8 | 0 |

*These are observed local runs, not guarantees that the configuration will reproduce the same score.*

The server caches computation for previously processed tokens. An agent conversation repeatedly sends overlapping context, so retaining that cached work can be valuable. With many long conversations sharing a limited cache, useful state can be evicted before it is reused.

The measurements were consistent with that problem: the higher-concurrency run had much more eviction and much less reuse. Keeping fewer conversations active helped the server reuse work instead of repeatedly processing context.

This also exposed a measurement issue. A cache-hit gauge was close to 99.87%, while the token counters indicated only 30.8% reuse. Those values could not be treated as interchangeable descriptions of the workload. In a separate replay tool, an impossible reported hit rate of 307.3% turned out to be a denominator bug.

The lesson was to check what a metric counts before using it to explain performance. A reassuring dashboard value is not enough if the underlying workload tells a different story.

## 4. A faster component does not necessarily make the agent faster

Assignment 4 also included experiments with serving settings. One example was changing decode CUDA-graph coverage for batch sizes one through eight.

In a repeated benchmark, decode time fell by 22.6%. However, the multi-turn benchmark improved by only 2.1%. The full agent runs did not establish a clear overall benefit, and the final engine configuration returned to the course’s basic settings.

The gap mattered because decoding is only part of an agent’s execution. A task also spends time processing input, running tools, waiting for commands, and deciding what to do next. Reducing the cost of one stage may have little effect if other stages dominate.

Some changes also introduce tradeoffs. A serving configuration might improve a short throughput benchmark while reducing the memory available for the long conversations in the actual workload.

I learned to use microbenchmarks to investigate a mechanism, then check whether that mechanism matters in the complete run. A faster benchmark was a reason to investigate further, not sufficient evidence to keep a change.

## 5. Cutting off reasoning sooner did not fix repeated reasoning

Assignment 5 made a different problem visible: responses that used the entire output budget without producing a tool call.

In the baseline, 27 replies reached the 16,384-token cap without calling a tool. Together, those replies consumed 5,758 seconds of model time. Because tasks ran concurrently, this is summed request time, not elapsed wall-clock time.

For Trial 1, I lowered the output cap to 12,000 tokens. The hypothesis was that stopping long replies earlier would leave more time for useful work. I also added diagnostics for how responses ended, how much reasoning and answer content they contained, and whether they included tool calls.

The lower-cap run had 66 capped replies without tool calls. All 66 contained reasoning but no answer content. Their combined model time was 11,042 seconds, about 92% higher than the baseline’s corresponding total. Four tasks ended after three consecutive capped replies without tools, compared with one in the baseline.

The code explained why this was a problem. Reasoning arrived in a separate response field, but the conversation history retained the answer content and tool calls. When a capped reply contained only reasoning, that reasoning was discarded. The next request added a generic reminder but little useful new information. After capped replies, prompt length grew by a median of only 25 tokens.

Lowering the cap changed when the model was interrupted. It did not fix what the loop did afterward.

For Trial 2, I restored the 16,384-token cap and added one recovery request. When an ordinary reply ended with `finish_reason="length"` and no tool calls, the next request was a recovery request.

For that recovery request only, I turned off the model’s thinking mode so it could respond without generating another long reasoning sequence. The next ordinary request used the default thinking mode again. A recovery reply could not trigger another recovery.

A live probe confirmed that the switch returned a valid tool call without reasoning, while the normal control returned reasoning. During the successful local Trial 2 run, 35 replies triggered recovery. Of those, 34 recovery requests were sent, and all 34 returned valid tool calls. The remaining recovery was not sent because its task ended first.

That established that the mechanism worked. It did not establish improved task success.

The 14 tasks in which recovery occurred produced no solves. A valid tool call means the agent can continue interacting with the environment; it does not mean the action is useful or that the task will finish correctly.

This became one of the clearest lessons of the project: recovering execution and recovering correctness are separate goals.

## 6. Failure handling needs to distinguish why a request stopped

Some apparently poor evaluations were infrastructure failures.

Two A5 runs scored 4/89 and 11/89 after connection failures. I excluded them from comparisons of agent quality. They were still useful operational evidence: an evaluation depends on the entire connection between the agent and the model server remaining available.

A subtler issue appeared in timeout handling. In the baseline, 11 requests were recorded as API failures even though their timeouts were bounded by the task’s remaining time. The task deadline had arrived while the request was still running.

Treating those events as server failures could activate the shared cooldown intended to protect against an unhealthy API. That risks delaying other workers even when the server is functioning normally. Trial 1 classified these as deadline cuts instead.

The general lesson was that failure categories need to preserve cause. A task deadline, a transient server error, and an unavailable connection may all stop a request, but they call for different responses.

## 7. A higher score is not automatically evidence of a better configuration

The valid local A5 totals were 17/89 for the baseline, 13/89 for Trial 1, and 22/89 for Trial 2. Taken alone, those numbers suggest that Trial 2 improved the agent.

But all three runs used random task order and a two-hour limit. They opened 62, 55, and 63 tasks respectively. Some tasks received substantial working time in one run and almost none in another.

Among the 41 tasks opened by both the baseline and Trial 2, each run solved 12. That does not prove the configurations are equivalent: even shared tasks can receive different time budgets, and the runs remain stochastic. It does mean that the overall increase from 17 to 22 is insufficient evidence to credit recovery with five additional solves.

Variation was visible in earlier assignments too. The same A3 submission was reported to score both 16/26 and 12/26. In A4, the same eight-worker configuration ranged from 16 to 21 solves across local runs.

Local and leaderboard results also answered different questions. The local A5 runs had a two-hour limit and six live tasks. The official evaluation allowed a longer run. My final submission solved **30/89 Terminal-Bench tasks in 3 hours 13 minutes**, meeting the Accurate baseline. It separately solved **7/26 tasks in 2 hours 13 minutes** in the additional evaluation.

Those are the final outcomes, but they do not isolate the contribution of any individual change.

## What I would carry into the next project

If I started again, I would add logging earlier and check that the agent’s changes were being submitted correctly before adjusting its behavior. I would also repeat experiments under the same conditions instead of relying on one good run. For each change, I would check both whether it worked as intended and whether it helped solve more tasks.

Over these assignments, I learned to look more closely at where things were going wrong. Sometimes the patch was incomplete. Sometimes too many workers were competing for cache space. Sometimes the model spent minutes generating reasoning that the agent then discarded.

Understanding those problems helped me make better decisions about what to change and what to leave alone. It also taught me that an experiment can be useful even when it does not produce a higher score.

## AI use

I used AI to polish my writing, and correct grammatical errors.