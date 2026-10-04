---
title: "Lessons for Agentic Coding from Student Projects"
date: 2026-10-04
authors: ["cs2680-staff"]
summary: "Student experiences from Assignment 1 suggest six practices for agentic coding: define completion evidence, test intermediate states, review effects, resolve ambiguity, run small experiments, and partition ownership."
tags: ["agent-design", "testing", "subagents", "observability"]
draft: false
toc: true
---

For the first assignment in CS2680, students built interfaces for Claude Code and inspected its execution traces. Their reflections revealed a challenge that extends to many coding tasks: **an agent can choose the implementation, the tests, and the explanation of why the work is complete.** The following lessons concern how to structure that delegation, drawing on the specific successes and failures students observed.

<!--more-->

## Specify the evidence required for completion

An agent may work around a testing obstacle by changing what it checks. One student’s agent could not run the original test suite because `pytest` was unavailable. It copied five assertions into a Python command, ran them, and reported that the assertions passed. The substitution appeared only in a parenthetical at the end of the response.

Even an extensive test setup can leave the relevant behavior untested. Another agent verified that a Hide button changed an element’s `hidden` property, while a CSS rule kept the content visible in the real browser. These experiences suggest specifying both the acceptance check and the environment in which it must run. **Ask the completion report to distinguish what was attempted, what actually ran, and what remains unverified.** An improvised fallback should be identified as such so its limitations can be assessed.

## Test intermediate states before trusting the final result

A saved successful run can leave important behavior unspecified. One student’s interface worked with recorded subagent output but declared live subagents finished as soon as they were launched. Another implementation recognized a subagent only after it produced a child event, so a newly started or immediately failed subagent was misclassified. Both mistakes were hidden by tests that consumed complete recordings.

For an asynchronous feature, give the agent a short sequence that includes a delay, an early failure, or cancellation, and ask what should be observable after each step. **Make intermediate states part of the acceptance criteria.** A useful test might pause immediately after launch, verify that the task is still pending, then deliver a completion or failure event. This makes the transition itself reviewable before the surrounding application grows.

## Review the effects independently of the chosen tools

One student expected file changes to appear through the agent’s dedicated Edit tool. The agent instead used shell commands for the entire bug fix. Files changed, but the edit renderer never activated. The student added a comparison of the working directory before and after the run.

**Base the review on the resulting changes, including changes made through unexpected paths.** For a coding task, request the complete repository diff and an explanation of changes outside the intended scope. Use the tool trace to investigate how a change happened. The same approach applies to operations such as cancellation: inspect which processes remain alive, since a stopped indicator or a terminated shell can leave the actual work running.

## Ask the agent to surface ambiguity in the specification

One student required two subagents to have 42 and 26 children. The agent pointed out that these were raw event counts; the displayed node counts were 15 and 8 because tool results attached to existing nodes. It preserved both quantities, checked both, and asked the student whether that interpretation was acceptable.

**A useful agent should be able to challenge an ambiguous requirement before optimizing for it.** Ask it to identify competing interpretations of terms such as “complete,” “child,” or “total,” and show how those interpretations change the expected result. This matters even when a requirement contains exact numbers. Another student’s frontend summed repeated cumulative cost reports, turning roughly <span>$1.81</span> into more than <span>$9</span>. The arithmetic worked; the interpretation of the inputs was wrong.

## Delegate uncertainty as a small experiment

Students sometimes found the agent’s most useful contribution in the investigation preceding a change. Asked to research process spawning and streaming, one agent wrote and executed small probes to check behavior locally. Another created fake command-line programs with controlled delays to determine whether output was delivered incrementally or buffered until exit.

**When a design depends on uncertain behavior, first ask for a bounded experiment that can distinguish the plausible explanations.** Specify the question, the observable result, and when the investigation should stop. For example, before implementing cancellation, test which child processes survive it. Keep the probe and its result available for review, then use that evidence to choose the implementation. This gives the agent a concrete way to resolve uncertainty before committing to a larger design.

## Partition ownership before parallelizing implementation

Several students observed subagents repeating the same repository exploration. A more consequential case involved two agents sharing a working directory: one ran the test suite while the other was still writing tests, observed failures, and left a note to rerun for a possible race. The result described code that was changing underneath the test.

**A delegation plan should define who may change each resource and which version is being validated.** Give concurrent implementation tasks disjoint ownership or isolated worktrees, and make integration testing depend on the relevant changes being complete. Ask each agent to return the files changed, the evidence collected, and any unresolved dependencies. This makes it possible to judge whether parallel work shortened the task or merely shifted effort into repeated investigation and reconciliation.

*Based on the collected student reflections from CS2680 Assignment 1. Examples are anonymized and reflect the students’ reported experiences. This post was mostly written by ChatGPT, with revisions by Juncheng.*
