---
title: "Six ways to watch a coding agent"
date: 2026-10-04
authors: ["cs2680-staff"]
summary: "The standout Assignment 1 interfaces: how subagents split the work, where a run's time went, and controls you can see."
tags: ["agent-ui", "observability", "subagents", "showcase"]
draft: false
cover: "cover.webp"
coverAlt: "A grid of six screenshots of student-built apps for watching Claude Code runs."
coverCaption: "Top: Subagents as a team, Intent Timeline, Patchwork. Bottom: Controller, Sankey Flow, Fork View."
toc: true
---

Assignment 1 asked everyone to put a web page in front of Claude Code's headless mode. Type a
prompt; watch the agent's tool calls stream in with their status; see what the run cost; send
a follow-up in the same session; find each subagent's work nested under the call that started
it; and get an outline of the whole trajectory.

We went through all 68 demos. Most built the same sensible thing: a chat-like log of
collapsible tool-call cards, an outline beside it and a cost line underneath, much like the
assignment's mockup. That is a perfectly good answer. The six designs below went further. Each
one asks what the person supervising an agent actually needs to see, and answers with something
a log of tool calls can't show on its own.

All six are in [CS2680-Assignment1-Mads-Lens](https://github.com/HarvardMadSys/CS2680-Assignment1-Mads-Lens),
one folder per app. Each app bundles recorded runs, so you can try it without installing Claude
Code or spending any usage.

<!--more-->

## What a log of tool calls hides

A log shows what happened, in order. Three things are hard to see in it:

- **Delegation.** A subagent becomes an indented block, not a worker with an assignment and a
  result.
- **Time.** A call that took 4 ms looks the same as one that took 40 s.
- **Control.** The model, the effort level and how much to delegate are set in a prompt, where
  you can't see them.

The sections below take these one at a time.

## Subagents as a team

### Saul Richardson: Subagents as a team

Saul Richardson's Subagents as a team treats delegation as something to manage. Above the
conversation sits a strip of cards: the main session, then one card per delegate with its
status and current activity. Click a delegate and the whole view scopes to it, with its
assigned task, its activity, its numbers and its report. The composer spells out the rule:
"This replies to the session. A delegate is part of it and has no conversation of its own."

![A dark interface with a row of agent cards above the conversation; one delegate card is selected and the view below shows its task, activity and report](richardson-delegate.webp "Subagents as a team after a run from its own test fixtures, scoped to one of three delegates: 54 s, 5 tool calls, 32k tokens.")

Try it: [`subagents-as-a-team/`](https://github.com/HarvardMadSys/CS2680-Assignment1-Mads-Lens/tree/main/subagents-as-a-team)

### Djordje Ivanovic: Patchwork

Djordje Ivanovic's Patchwork turns subagents into characters, each with a name and an avatar,
and its Lanes view gives every agent a column. The lead's column reads like a delegation log:
an *Assigned* card for each task and who took it, then a *Result returned* card with the first
lines of each answer. Every subagent's column opens with "Assigned by Djordje" and closes with
the result it handed back. Runs of similar calls collapse into a phrase ("13 steps ·
Inspecting files · Read 13 files"), failures are pulled out under *Steps needing attention*,
and the panel is candid about how it treats time: "compact lanes, not elapsed time."

![Four lanes: the lead's lane with Assigned and Result returned cards, and three subagent lanes with grouped steps and returned results](ivanovic-lanes.webp "Patchwork's Lanes view on a recorded run with five parallel subagents. The lead's lane lists each assignment and each returned result.")

Try it: [`patchwork/`](https://github.com/HarvardMadSys/CS2680-Assignment1-Mads-Lens/tree/main/patchwork)

### Zoe Jingyi Liu: Fork View

Zoe Jingyi Liu's Fork View forks the log itself. When subagents run in parallel they get
side-by-side columns in the trajectory, each with its brief, step count and duration, and a
subagent that delegates again forks again inside its own column. The app is just as careful
about how a run ends. While a run streams, the header shows a lower bound on the cost
(`≥$0.2496`) that turns into the exact figure when the result arrives, and a stopped run says
what it kept: "Run stopped. Everything recorded before this point is kept."

![Two subagent cards side by side, the left one containing two more nested subagents](liu-columns.webp "Fork View replaying its bundled parallel-deep example: two surveys run side by side, and each one delegates further inside its own column.")

Try it: [`fork-view/`](https://github.com/HarvardMadSys/CS2680-Assignment1-Mads-Lens/tree/main/fork-view)

## Where the time went

### Ibrahim Khaliliya: Sankey Flow

Ibrahim Khaliliya's Sankey Flow swaps the outline for a Sankey diagram. A run flows into its
actors (the main agent and each subagent), then into the actions they took (LLM turns, Bash,
Read, Edit, Agent), then into outcomes. Band width counts calls, or time at the flip of a
toggle, and hovering a node gives its share of both. In the run below, Bash is 35% of the calls
and 1% of the time; the minutes go to the LLM turns. A failed call becomes its own outcome, and
you can trace it back through the diagram.

The rest of the page leans the same way, with gauges for time to first token and time per
output token, and an animated cat that sleeps, waits, walks or runs with the token rate.

![A Sankey diagram flowing from one run to three actors, then to actions such as LLM turn and Bash, then to Completed and Failed outcomes, with a tooltip on the Bash node](khaliliya-flow.webp "Sankey Flow on a recorded run with two subagents (a recording from another app). Hovering Bash: 9 calls, 35% of the column, but 1.1 s, 1% of the time.")

Try it: [`sankey-flow/`](https://github.com/HarvardMadSys/CS2680-Assignment1-Mads-Lens/tree/main/sankey-flow)

### Eric Gong: Swimlanes

Eric Gong's Swimlanes adds a Timeline tab with one swimlane per agent. Each call is a block
placed at its real start time and sized by its duration, so two subagents working at once show
up as two lanes busy in the same seconds, and a slow call looks slow. A zoom slider, a
follow-live switch and a click-through to each call's input and output make it usable while a
run is going. The composer also takes a model for the main agent and a policy for the
subagents' models, and each subagent reports what it asked for and what it ran on
(`asked for sonnet · ran on sonnet-5`).

![A timeline with three swimlanes: the main agent with two long Agent bars, and one lane for each subagent with short tool blocks in the same window of time](gong-timeline.webp "Swimlanes on a recorded two-subagent run (a recording from another app). The main lane's two Agent bars span the same seconds as the subagents' own lanes.")

Try it: [`swimlanes/`](https://github.com/HarvardMadSys/CS2680-Assignment1-Mads-Lens/tree/main/swimlanes)

## Controls you can see

### Raul Romero: Controller

Raul Romero's Controller borrows from music hardware (the inspiration is Teenage Engineering):
an effort knob, keys for the model, a fader for the number of subagents, a delegation switch,
and LCD-style readouts for cost, time, turns and calls. Settings that usually live in a prompt
("use four subagents") become controls that stay in view. A radial scope on the right draws the
main agent as a hub with a satellite for each subagent, labelled with its call count.

![A dark hardware-style interface with a knob, model keys, a fader, LCD readouts, a stream of tool calls and a radial diagram of agents](romero-controller.webp "Controller replaying a recording from another app. The scope at the top right shows the main agent and four subagents.")

Try it: [`controller/`](https://github.com/HarvardMadSys/CS2680-Assignment1-Mads-Lens/tree/main/controller)

## Across the class

A few patterns from the rest of the designs:

- The most common additions were a Stop button, replay of recorded runs, permission controls
  and diffs of changed files.
- A real time axis was rare: only a handful of designs put calls on a clock.
- Many designs, independently, gave each running subagent a status line: what it is doing
  now, how many tools it has used, its tokens and its elapsed time. It's a small idea, and one
  of the most useful.
- Most designs drew the forking outline from the assignment's mockup. The ones above changed
  the main view instead.

If one of these designs is yours, think about writing it up as your Assignment 1 post. The
[publishing guide](/publish/) has the steps.
