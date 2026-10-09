---
title: "Controller: a Teenage Engineering-inspired terminal for Claude Code"
date: 2026-10-09
authors: ["Raul Romero"]
summary: "Controller turns Claude Code's settings into hardware: an effort knob, model keys and a subagent fader set up each run, with cost, model and agents always in view, so you steer the agent with controls instead of prompts."
tags: ["agent-ui", "subagents", "observability", "showcase"]
draft: false
cover: "cover.webp"
coverAlt: "Controller replaying a four-subagent run: an effort knob, model keys and a subagent fader on the left, folded tool-call cards in the centre, and a radial scope with the main agent and four subagents on the right"
coverCaption: "Controller replaying a run in which the main agent delegates to four subagents."
---

<style>
/* Posts on X render as static quotes (privacy mode, no X script); this frames them as cards. */
.note-body blockquote.twitter-tweet {
  max-width: 560px;
  margin: var(--s5) 0;
  padding: var(--s4) var(--s5);
  border: 1px solid var(--border);
  border-radius: var(--r-lg);
  background: var(--surface);
  box-shadow: var(--shadow-1);
  font-size: 16px;
  line-height: 1.55;
  color: var(--ink-2);
}
.note-body blockquote.twitter-tweet::before {
  content: "Post on X";
  display: block;
  margin-bottom: var(--s2);
  font-size: 12px;
  font-weight: 700;
  letter-spacing: .06em;
  text-transform: uppercase;
  color: var(--ink-4);
}
.note-body blockquote.twitter-tweet p { margin: 0 0 var(--s3); color: var(--ink); }
</style>

Agent interfaces are increasingly leaning towards the complete autonomous creation of software, to
an extent that the user is less in the loop. In 2022, GitHub Copilot gave users code
completion. In 2023, Cursor began introducing file-level edits. In 2024, v0 introduced
cloud-based creation of projects tested in its own sandbox. And since November 2025, Claude Code and
Codex have meaningfully increased not just model capabilities but their usefulness in coding
harnesses. While the trend has meant that users are able to leverage these interfaces to create
longer-running tasks and shift towards goal engineering, in certain use cases users want to be in
control, even if their agents are generating all the code.

{{< x user="karpathy" id="2015883857489522876" >}}

This long tweet from Karpathy captures the essence. Agents have rendered what used to be meaningful
architecture decisions obsolete, often keeping the user out of the loop by choosing the standard or
following their preferences. This is valuable. But it has shifted the decisions that users should
control in order to maximize the quality of outputs from their agents and their steerability, such
as: How many sub-agents should be created at once? What are the patterns that the agent should
refer to when creating a design? How should it use the browser to test the page? How much effort
should be spent on a task? How should an agent team be set up?

As a design engineer who runs agentic workflows on a daily basis (see below), deciding how to
control (or not), what to control, and when to make that decision is key.

{{< x user="Raul_RomeroM" id="2108400597573742889" >}}

So, with the advice of my professor Juncheng Yang and TF Yiyu Liu, I created a Teenage
Engineering-inspired Claude Code terminal (called ‘Controller’) that provides visible knobs that
allow users to reduce the amount of prompting they do and quickly take relevant actions. It merges
the elements of Claude Code with physical levers users can use, and gives them visibility into
their usage, consumption and model.

This visual identity and the manual knobs provide a more bespoke experience that can give design
engineers (and developers in general) a different feel of the model, and an experience that feels
easier to manage, with lower cognitive load than prompting every adjustment.

At the top, users can observe consumption and model, and can easily instruct Claude Code to merge
the changes into main.

![The top rail: readouts for cost, time, turns, calls and route on black displays, then keys for merge, new session, theme and full screen](top-rail.webp "The top rail. The readouts show cost, elapsed time, turns, tool calls and the model · effort route.")

On the left column, the menu provides users the ability to more easily tweak the number of
sub-agents and agents they would require (or the max number of agents available) for either the
conversation or a given turn.

On the left, users can manage the number of agents and sub-agents and can search for skills that
they'd like to adopt in the instance.

![Two panels from the left column. Left: the effort knob set to high, model keys with sonnet selected, a custom auditor agent, delegation required switched on and the subagent fader at 7. Right: the capabilities panel with a skills.sh search for frontend design listing results with install counts and add keys](left-column.webp "The left column. The knob sets effort, the keys pick the model, and the fader caps concurrent subagents; the capabilities panel searches skills.sh.")

At the bottom, users can manage the files, provide input with audio, or manage the directory.

![The command deck with run settings open: the working directory, extra directories, bypass permissions and continue session switches, then the file, microphone and run keys with one attached file](deck.webp "The command deck. The + knob opens run settings; file attaches context, and the microphone dictates a prompt.")

[Explore Controller here](https://github.com/HarvardMadSys/CS2680-Assignment1-Mads-Lens/tree/main/controller).

## AI use

Controller was built with Claude Code (Claude Opus 5.5). GPT-6 Astra 3D modelled the Controller
design in Blender that Controller's texture was developed from.
