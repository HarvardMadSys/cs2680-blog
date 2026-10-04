---
title: "What CS2680 Students Want from Claude Code"
date: 2026-10-04
authors: ["cs2680-staff"]
summary: "A qualitative synthesis of 69 Assignment 1 write-up sections: students ask for clearer decisions, editable context, visible costs, reliable delegation, and evidence of verification."
tags: ["agent-ui", "observability", "user-feedback", "context-management"]
draft: false
toc: true
---

For Assignment 1 in CS2680, students used Claude Code to build a web interface for observing and interacting with a coding agent. They worked on both sides of the interface: directing an agent to build software, then making its activity understandable to someone watching it.

We asked them what one thing they would change about Claude Code. Across the 69 collected write-up sections, a recurring theme emerged: students want to delegate work while retaining control over decisions, context, cost, and verification.

Their suggestions are unusually concrete because they come from building on top of the agent. Some concern behavior; others concern the event stream that a frontend must interpret. Some ask for better defaults or easier access to existing controls. The examples below are students’ reported experiences in their own versions and environments.

<!--more-->

## Explain decisions in time for users to intervene

Several students could see which files an agent opened and which commands it ran, yet still struggled to understand why it chose its next step. One wanted a short account of a debugging agent’s current hypothesis and the evidence narrowing its investigation. Another wanted to see what work remained and when a discovery forced the agent to backtrack.

These requests point toward a useful progress update: what the agent is trying to establish, what it has learned, and what it will check next. That gives the user an opportunity to catch a misunderstanding while the investigation is still underway.

Students also asked for less output. Long command traces and repetitive commentary made previous prompts and meaningful results difficult to find. A concise overview with expandable details could serve both needs: immediate orientation and deeper inspection when something looks wrong.

Visibility should help the user make a decision. A short explanation of the next action, supported by observable evidence, can do that without exposing private reasoning.

## Ask about consequential choices and respect the scope

One student wanted Flask, but the agent had already built the server around Python’s built-in HTTP server before that preference was discussed. Another discovered that two interface panels had been implemented with their roles reversed. A brief plan would have exposed the misunderstanding before several files changed.

Students wanted targeted questions about architecture, layout, and interaction design. They also wanted a small request to remain small. One reported changes beyond the requested feature even after explicitly instructing the agent to preserve the rest of the code.

The feedback suggests making the intervention points explicit: a short plan before substantial work, questions when a choice materially affects the product, and a clear account of which files will change. For headless frontends, students also wanted an easy way to approve or deny an individual action during a run and then continue.

Autonomy needs a scope the user can inspect and revise. The right amount of interaction can vary by task: rapid iteration on a prototype calls for a different workflow from a change to a project the user already understands and cares about.

## Let users revise what the agent remembers

One student proposed a particularly useful instruction: “branch here, keep the file layout, drop the debugging.” It captures a need that a fresh session and a full continuation each address only partially.

Students wanted to carry useful decisions into a new branch while discarding irrelevant investigation. They also wanted to remove mistaken assumptions. One described correcting an error, then seeing the original misunderstanding return later because both the mistake and its correction remained in the conversation.

A correction should change the context the agent relies on. Appending another instruction can leave the user uncertain about which version will guide the next action. Students asked for ways to update, discard, or explicitly supersede a piece of session memory.

There was an efficiency concern too. One student’s analysis reported cached tokens re-read growing from roughly 13,000 on the first request to 109,000 on the 99th, even though the questions had not grown. Other suggestions included loading detailed context only when needed and warning when continuing a long session may be inefficient. These observations motivate evaluating more selective context management.

## Show the cost while it can still affect the run

One student discovered that runs were billed to a startup’s API account rather than the university account they expected to use. The requested fix was straightforward: show the active account and billing source clearly at launch, including in headless output.

Others wanted running cost and remaining usage to be visible. Token counters helped, but students building frontends wanted dollar amounts supplied by the system so they would not have to reconstruct pricing themselves. They wanted to see expensive delegation developing early enough to change course.

Cost information is most useful before the work is finished. Students proposed limits on delegation depth and spending, warnings about expensive runs, and cheaper or local models for simple tasks. Those routing ideas remain proposals; the reflections do not demonstrate their performance. One student also noted that an existing budget cap had gone unused, illustrating the importance of making controls discoverable.

Students also connected latency to their workflow. For interface development, one preferred getting an initial version quickly, inspecting it, and deciding what to change next. Faster iterations let the user discover requirements through interaction with the product. That is a useful design target alongside the quality of a single completed run.

## Make delegated work easy to follow and reconcile

Students wanted an overview of each subagent’s assignment, status, findings, and dependencies. They wanted to inspect details without reading every subagent conversation to learn what had happened.

One student reported that the main agent re-read files assigned to background subagents while those agents were still working. Another lost track of how the parallel work fit together. Their requests extended to the parent agent: explain which findings it accepted, identify disagreements or duplicated work, and check the combined result against the original request.

The preferences varied. One student wanted more proactive delegation for large tasks; another wanted tighter control after a deeply nested run became expensive. That variation argues for visible assignments and adjustable limits.

Delegation should preserve accountability for the final result. A user needs to understand what each worker contributed and how the coordinator used it.

## Report exactly what was verified

One student found that a Stop button worked on an empty page but disappeared when an earlier conversation was present. A general statement that testing had passed did not reveal that missing case. The student wanted the completion message to name the test and describe its setup.

Another reported that a later audit found regression tests weaker than the initial summary suggested. A third described visual defects that became obvious on opening a page the agent had been unable to inspect in a browser.

Students wanted completion reports to separate verified behavior, untested behavior, and assumptions. They also wanted agents to question misleading observations: one reported nearly an hour of debugging prompted by browser screenshots that appeared blank, even though directly checking the scroll position showed the page had scrolled correctly.

Verification claims need the evidence and conditions that support them. “Stop checked on an empty page; not yet checked with an existing conversation” tells the user what to try next. A count of passing tests leaves that work to inference.

## Give frontend builders a reliable event contract

Building a frontend exposed another set of requests. Students reported having to infer event relationships, parse display text, and record sessions to discover the format. They wanted a documented, versioned schema that made execution state explicit.

Their proposals included:

- Stable agent and parent identifiers on startup, progress, tool, and completion events.
- Consistent structured tool results for the main agent and subagents.
- Explicit pending states for asynchronous work and a clear signal that the whole run has ended.
- Structured outcomes that distinguish completion, blocked work, failure, and unresolved tasks.
- Logs that retain the initiating user prompt, with a supported relationship between streamed events and stored sessions.

The distinction between a finished run and a completed task was especially concrete. Students recorded runs labeled successful after a requested file could not be found or necessary actions were denied. Others observed multiple result events and needed to determine whether more work would follow.

The event stream should carry the state a user interface needs to display. Otherwise, each frontend must reconstruct that state from prose and special cases, with its own opportunities for misleading the user.

## Help students retain ownership of their code

Some students wanted Claude Code to help them understand the software as it grew. They asked for file-by-file diffs, clearer module structure, and a way to connect a visible interface change to the code implementing it.

One proposed an interactive debugging mode that would pause at an error and ask the student to identify the likely file or function. Another wanted to design the repository structure themselves and receive suggestions. These are concrete requests for a tool that can alternate between implementing, explaining, and teaching.

For a student, a useful result includes understanding enough to maintain and extend it. The same interface may need to support a quick prototype in one session and a guided investigation in another.

Together, these reflections offer a practical design test for coding agents: can the user notice a mistaken assumption, redirect delegated work, understand the cost, and judge the evidence for completion while those decisions still matter? The students’ proposals give us specific mechanisms to build and evaluate against that test.

*Based on the collected “One thing I would change about Claude Code” sections from CS2680 Assignment 1. Examples are anonymized; this is a qualitative synthesis of students’ reported experiences. This post was mostly written by ChatGPT, with revisions by Juncheng.*
