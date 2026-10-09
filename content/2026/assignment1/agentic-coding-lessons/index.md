---
title: "Lessons for Agentic Coding from Student Projects"
date: 2026-10-04
authors: ["cs2680-staff"]
summary: "Lessons from CS2680 student projects: make decisions and context editable, show costs and delegation, define reliable event states, and verify the behavior users actually depend on."
tags: ["agent-design", "agent-ui", "testing", "subagents", "observability", "user-feedback", "context-management"]
aliases: ["/2026/assignment1/claude-code-feedback/"]
draft: false
toc: true
cover: "cover.webp"
coverAlt: "Two students direct a coding agent through an interface showing delegated tasks, editable context, a budget dial, and verification checks."
coverCaption: "Delegating work while keeping decisions, context, cost, and verification visible. Illustration generated with AI."
---

For Assignment 1 in CS2680, students used Claude Code to build interfaces for observing and interacting with a coding agent. They worked on both sides of the interface: directing an agent to build software, then making its activity understandable to someone watching it.

Their project reflections and the 69 collected “One thing I would change about Claude Code” write-up sections reveal a common concern: **students want to delegate work while retaining control over decisions, context, cost, and verification.** An agent can choose the implementation, the tests, and the explanation of why the work is complete. The practices and interface requests below show how to make that delegation easier to inspect and revise.

These examples are students’ reported experiences in their own versions and environments. The feedback is a qualitative synthesis, and proposed controls are design ideas rather than demonstrated improvements.

<!--more-->

## Explain decisions in time for users to intervene

Several students could see which files an agent opened and which commands it ran, yet still struggled to understand why it chose its next step. One wanted a short account of a debugging agent’s current hypothesis and the evidence narrowing its investigation. Another wanted to see what work remained and when a discovery forced the agent to backtrack.

These requests point toward a useful progress update: what the agent is trying to establish, what it has learned, and what it will check next. That gives the user an opportunity to catch a misunderstanding while the investigation is still underway.

Students also asked for less output. Long command traces and repetitive commentary made previous prompts and meaningful results difficult to find. A concise overview with expandable details could serve both needs: immediate orientation and deeper inspection when something looks wrong. The request is for more visibility with less clutter: show progress and remaining work, briefly explain the current hypothesis, and connect the next action to the task.

Visibility should help the user make a decision. A short explanation of the next action, supported by observable evidence, can do that without exposing private reasoning.

## Resolve ambiguity and agree on the scope

One student wanted Flask, but the agent had already built the server around Python’s built-in HTTP server before that preference was discussed. Another discovered that two interface panels had been implemented with their roles reversed. A brief plan would have exposed the misunderstanding before several files changed.

Students wanted targeted questions about architecture, layout, and interaction design. They also wanted a small request to remain small. One reported changes beyond the requested feature even after explicitly instructing the agent to preserve the rest of the code.

The feedback suggests making the intervention points explicit: a short plan before substantial work, questions when a choice materially affects the product, and a clear account of which files will change. For headless frontends, students also wanted an easy way to approve or deny an individual action during a run and then continue.

Autonomy needs a scope the user can inspect and revise. Students wanted questions and options early enough to avoid changing course after substantial implementation. The right amount of interaction can vary by task: rapid iteration on a prototype calls for a different workflow from a change to a project the user already understands and cares about.

One student required two subagents to have 42 and 26 children. The agent pointed out that these were raw event counts; the displayed node counts were 15 and 8 because tool results attached to existing nodes. It preserved both quantities, checked both, and asked the student whether that interpretation was acceptable.

**A useful agent should be able to challenge an ambiguous requirement before optimizing for it.** Ask it to identify competing interpretations of terms such as “complete,” “child,” or “total,” and show how those interpretations change the expected result. This matters even when a requirement contains exact numbers. Another student’s frontend summed repeated cumulative cost reports, turning roughly <span>$1.81</span> into more than <span>$9</span>. The arithmetic worked; the interpretation of the inputs was wrong.

For interface work, students found screenshots, explicit geometry, and narrow edit boundaries more useful than broad prompts. Express a requirement as a condition with a check. For example, specify what should disappear when Hide is clicked and verify it in the browser. A design review before implementation can expose a consequential misunderstanding while it is still cheap to correct.

## Let users revise what the agent remembers

One student proposed a particularly useful instruction: “branch here, keep the file layout, drop the debugging.” It captures a need that a fresh session and a full continuation each address only partially.

Students wanted to carry useful decisions into a new branch while discarding irrelevant investigation. They also wanted to remove mistaken assumptions. One described correcting an error, then seeing the original misunderstanding return later because both the mistake and its correction remained in the conversation.

A correction should change the context the agent relies on. Appending another instruction can leave the user uncertain about which version will guide the next action. Students asked for ways to update, discard, or explicitly supersede a piece of session memory.

There was an efficiency concern too. One student’s analysis reported cached tokens re-read growing from roughly 13,000 on the first request to 109,000 on the 99th, even though the questions had not grown. Other suggestions included loading detailed context only when needed and warning when continuing a long session may be inefficient. Students also reported repeated repository exploration across sessions. Reusing verified project knowledge could reduce that work, provided users can remove stale facts and revise earlier decisions.

## Delegate uncertainty as a small experiment

Students sometimes found the agent’s most useful contribution in the investigation preceding a change. Asked to research process spawning and streaming, one agent wrote and executed small probes to check behavior locally. Another created fake command-line programs with controlled delays to determine whether output was delivered incrementally or buffered until exit.

**When a design depends on uncertain behavior, first ask for a bounded experiment that can distinguish the plausible explanations.** Specify the question, the observable result, and when the investigation should stop. For example, before implementing cancellation, test which child processes survive it. Keep the probe and its result available for review, then use that evidence to choose the implementation. This gives the agent a concrete way to resolve uncertainty before committing to a larger design.

## Show the cost while it can still affect the run

One student discovered that runs were billed to a startup’s API account rather than the university account they expected to use. The requested fix was straightforward: show the active account and billing source clearly at launch, including in headless output.

Others wanted running cost and remaining usage to be visible. Token counters helped, but students building frontends wanted dollar amounts supplied by the system so they would not have to reconstruct pricing themselves. They wanted to see expensive delegation developing early enough to change course.

Cost information is most useful before the work is finished. Students wanted live dollar costs alongside explicit budget controls, so the current spending and the limit would be visible together. They proposed limits on delegation depth and spending, warnings about expensive runs, and cheaper or local models for simple tasks. Those routing ideas remain proposals; the reflections do not demonstrate their performance. One student also noted that an existing budget cap had gone unused, illustrating the importance of making controls discoverable.

Students also connected latency to their workflow. For interface development, one preferred getting an initial version quickly, inspecting it, and deciding what to change next. Faster iterations let the user discover requirements through interaction with the product. That is a useful design target alongside the quality of a single completed run.

## Make delegated work easy to follow and reconcile

Students wanted an overview of each subagent’s assignment, status, findings, and dependencies. They also wanted to understand what context each worker had received. They wanted to inspect details without reading every subagent conversation to learn what had happened.

Users wanted to adjust the number of agents, delegation depth, and scope while a run was underway. A useful interface would let them revise responsibilities or limit further delegation as they learned more about the task.

One student reported that the main agent re-read files assigned to background subagents while those agents were still working. Another lost track of how the parallel work fit together. Their requests extended to the parent agent: explain which findings it accepted, identify disagreements or duplicated work, and check the combined result against the original request.

The preferences varied. One student wanted more proactive delegation for large tasks; another wanted tighter control after a deeply nested run became expensive. That variation argues for visible assignments and adjustable limits.

Delegation should preserve accountability for the final result. A user needs to understand what each worker contributed and how the coordinator used it.

Several students observed subagents repeating the same repository exploration. A more consequential case involved two agents sharing a working directory: one ran the test suite while the other was still writing tests, observed failures, and left a note to rerun for a possible race. The result described code that was changing underneath the test.

In one reported comparison, a six-agent run with delegation depth three took more than ten minutes and cost nearly <span>$15</span>. An earlier similar task took less than two minutes and cost about <span>$1</span>. The reflection describes the tasks as similar. It does not establish how much of the difference came from delegation, but it gives the user a reason to inspect the extra work and resource usage.

**A delegation plan should define who may change each resource and which version is being validated.** Independent reviews and distinct implementation tasks were useful when the work was separable. Give concurrent implementation tasks disjoint ownership or isolated worktrees, and make integration testing depend on the relevant changes being complete. Ask each agent to return the files changed, the evidence collected, and any unresolved dependencies. This makes it possible to judge whether parallel work shortened the task or merely shifted effort into repeated investigation and reconciliation.

## Give frontend builders a reliable event contract

Building a frontend exposed another set of requests. Students reported having to infer event relationships, parse display text, and record sessions to discover the format. Tasks could finish in a different order from the one in which they started, and background Bash tasks could resemble subagents. Students wanted a documented, versioned schema that made execution state explicit and helped the interface distinguish these cases.

Their proposals included:

- Stable agent and parent identifiers on startup, progress, tool, and completion events.
- Consistent structured tool results for the main agent and subagents.
- Explicit pending states for asynchronous work and a clear signal that the whole run has ended.
- Structured outcomes that distinguish completion, blocked work, failure, and unresolved tasks.
- Logs that retain the initiating user prompt, with a supported relationship between streamed events and stored sessions.

The distinction between a finished run and a completed task was especially concrete. Students recorded runs labeled successful after a requested file could not be found or necessary actions were denied. Others observed multiple result events and needed to determine whether more work would follow.

The event stream should carry the state a user interface needs to display. Otherwise, each frontend must reconstruct that state from prose and special cases, with its own opportunities for misleading the user.

A saved successful run can leave important behavior unspecified. One student’s interface worked with recorded subagent output but declared live subagents finished as soon as they were launched. Another implementation recognized a subagent only after it produced a child event, so a newly started or immediately failed subagent was misclassified. Both mistakes were hidden by tests that consumed complete recordings.

For an asynchronous feature, give the agent a short sequence that includes a delay, an early failure, or cancellation, and ask what should be observable after each step. **Make intermediate states part of the acceptance criteria.** A useful test might pause immediately after launch, verify that the task is still pending, then deliver a completion or failure event. This makes the transition itself reviewable before the surrounding application grows.

## Specify completion evidence and report what was verified

An agent may work around a testing obstacle by changing what it checks. One student’s agent could not run the original test suite because `pytest` was unavailable. It copied five assertions into a Python command, ran them, and reported that the assertions passed. The substitution appeared only in a parenthetical at the end of the response.

Even an extensive test setup can leave the relevant behavior untested. Another agent verified that a Hide button changed an element’s `hidden` property, while a CSS rule kept the content visible in the real browser. Other reports described verification where zero tests had run or permissions had blocked the checks.

These experiences suggest specifying both the acceptance check and the environment in which it must run, then checking the reported evidence manually. **Ask the completion report to distinguish what was attempted, what actually ran, and what remains unverified.** An improvised fallback should be identified as such so its limitations can be assessed.

One student found that a Stop button worked on an empty page but disappeared when an earlier conversation was present. A general statement that testing had passed did not reveal that missing case. The student wanted the completion message to name the test and describe its setup.

Another reported that a later audit found regression tests weaker than the initial summary suggested. A third described visual defects that became obvious on opening a page the agent had been unable to inspect in a browser.

Students wanted completion reports to separate verified behavior, untested behavior, and assumptions. They also wanted agents to question misleading observations: one reported nearly an hour of debugging prompted by browser screenshots that appeared blank, even though directly checking the scroll position showed the page had scrolled correctly.

Verification claims need the evidence and conditions that support them. “Stop checked on an empty page; not yet checked with an existing conversation” tells the user what to try next. A count of passing tests leaves that work to inference.

## Review the effects independently of the chosen tools

One student expected file changes to appear through the agent’s dedicated Edit tool. The agent instead used shell commands for the entire bug fix. Files changed, but the edit renderer never activated. The student added a comparison of the working directory before and after the run.

**Base the review on the resulting changes, including changes made through unexpected paths.** For a coding task, request the complete repository diff and an explanation of changes outside the intended scope. Use the tool trace to investigate how a change happened. The same approach applies to operations such as cancellation: inspect which processes remain alive, since a stopped indicator or a terminated shell can leave the actual work running.

## Help students retain ownership of their code

Some students wanted Claude Code to help them understand the software as it grew. They asked for file-by-file diffs, clearer module structure, and a way to connect a visible interface change to the code implementing it.

One proposed an interactive debugging mode that would pause at an error and ask the student to identify the likely file or function. Another wanted to design the repository structure themselves and receive suggestions. These are concrete requests for a tool that can alternate between implementing, explaining, and teaching.

For a student, a useful result includes understanding enough to maintain and extend it. The same interface may need to support a quick prototype in one session and a guided investigation in another.

These lessons suggest a workflow: inspect real traces early, agree on scope and concrete acceptance checks, investigate uncertain behavior with small probes, and build in small increments. Iterate cheaply with recordings, then verify intermediate states and final behavior in the real browser and live runtime. Review the resulting changes, resource usage, and evidence for completion, while keeping decisions and context open to correction throughout.

*Based on the collected student reflections, including the 69 “One thing I would change about Claude Code” write-up sections, from CS2680 Assignment 1 and the lecture slides summarizing the lessons and feedback. Examples are anonymized and reflect the students’ reported experiences. This post was mostly written by ChatGPT, with revisions by Juncheng.*
