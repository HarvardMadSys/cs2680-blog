---
title: "Why Claude Code Kept Reaching for Bash"
date: 2026-10-06
authors: ["cs2680-staff"]
summary: "If your Assignment 1 viewer filled up with Bash cards, your prompts were mostly not to blame. Claude Code told the agent to use the shell, dropped the shell tool's usual warning, and in most installs had no Grep or Glob. Here is what the session logs show."
tags: ["agent-design", "observability", "tool-use", "session-logs"]
draft: false
toc: true
---

If you built a trajectory viewer for Assignment 1, you probably watched a lot of Bash go by.
Students expected their interfaces to fill up with Read, Edit and Write cards, and many built
careful renderers for them. What mostly arrived was `cat`, `sed -n`, heredocs and little Python
patch scripts, each one wrapped in a Bash card. In one case from our [lessons from the
assignment](/2026/assignment1/agentic-coding-lessons/), an agent did an entire bug fix through the
shell, and the student's edit view never lit up once.

Our first guess was the model, or the way people prompted it. That guess was mostly wrong. When we
went through the session logs that students submitted, we found that Claude Code itself had told the
agent to work in the shell. It had also deleted the shell tool's usual warning against doing that,
and most installations didn't offer a dedicated search tool at all.

<!--more-->

## Where the file work went

Claude Code has dedicated tools for files: Read, Edit and Write, plus Grep and Glob for searching on
some installations. Every one of those jobs can also be done in a shell. You can read with `cat` or
`sed -n`, search with `grep` and `find`, and write with a heredoc, `sed -i` or a short script. Across
the build sessions of 61 students, Bash did one of these jobs 7,909 times.

![Share of each file job done through Bash in Assignment 1 build sessions: reading files 29% (1,354 of 4,745 calls); searching and listing 97% (1,404 of 1,447 calls); writing and editing files 52% (5,151 of 9,874 calls).](why-bash-jobs.svg "Figure 1. How much of each file job went through Bash, across the build sessions of 61 students.")

Searching was almost all Bash, writing about half, and reading a bit under a third. Three things in
Claude Code account for most of that picture.

## Claude Code asked for it

In auto mode and bypass-permissions mode, Claude Code can slip a system reminder into the
conversation. During the assignment, that reminder always read like this (we've added the line
breaks here and in the other quoted texts):

```text
Do your work through the Bash tool wherever it can accomplish the job: read files
with cat, head, or sed -n, search with grep and find, and make file changes with
sed, heredocs, or short scripts, rather than using the dedicated Read, Edit, or
Write tools. Fall back to a dedicated tool only when Bash genuinely cannot do the
job.
```

None of this is hidden. Claude Code writes the reminder into the session transcript under
`~/.claude/projects/`, as an `auto_mode` record with `"bashFirst":true` and the exact text the model
received. Of those 7,909 shell calls, 88% happened with the reminder sitting in the conversation.

And it made a big difference. Figure 2 compares calls made with the reminder in context against
calls in sessions that never got it.

![Share of each job done through Bash without the bash-first reminder versus with it in context: reading files: 8% versus 41%; writing and editing files: 8% versus 67%; reads and edits by Opus 5 main agents: 10% versus 78%; the same 22 sessions, before and after: 6% versus 82%; searching (no Grep or Glob either way): 89% versus 100%.](why-bash-reminder.svg "Figure 2. How much of each job went through Bash, in calls with no reminder (grey) and with the reminder in the conversation (crimson).")

The row we find most convincing is the fourth. In 22 sessions the reminder showed up partway
through, usually because the student flipped into auto mode, so we can compare a session with
itself. Reads and edits through the shell went from 6% to 82%, and they rose in 21 of the 22
sessions (the other one was already at 100%). You can see the switch in a single log. In one
session, the agent makes five changes with Edit and creates a file with Write. Then the reminder
arrives, and its very next file operations are `sed -n` reads and Python patch scripts.

![Share of reads and edits done through Bash in 22 sessions where the reminder appeared partway through. Overall 6% before and 82% after; 21 of 22 sessions went up.](why-bash-sessions.svg "Figure 3. Reads and edits through Bash in the 22 sessions where the reminder arrived partway through. Each line is one session, before and after.")

The reminder also sticks around after the mode that triggered it. Once it is in the conversation, it
stays there. Claude Code does have an "Exited Auto Mode" notice that tells the agent to go back to
the dedicated tools, but it turned up only three times in our logs. When students typed prompts in
default mode with an old reminder still in the conversation, 81% of the agent's reads and edits went
through Bash. In default-mode sessions that never got the reminder, it was 9%.

Sometimes the agents simply told the students. One student asked why the agent had used `cat`
instead of the Read tool, and the agent said the instructions for bypass mode told it to prefer
Bash. A few others mentioned a "Bash-first" default while explaining that they would set it aside,
since the student had asked for Read and Edit by name.

Our favorite example comes from a student whose app showed nothing but Bash cards in live runs.
They asked their agent why. The agent dug through the run's transcript, found the reminder, and
then ran the same prompt under two settings. With `--dangerously-skip-permissions`, which puts the
run in bypass mode, the agent used Bash and nothing else. With `--permission-mode acceptEdits`, the
reminder never appeared and the run used Read, Edit and Write. The agent also worked out why the app
couldn't have shown any of this: the stream-json output these apps read doesn't include the
reminder at all.

## The warning that disappeared

Each request to the model carries a description of every tool. The Bash tool's description
normally includes this line:

```text
IMPORTANT: Avoid using this tool to run `cat`, `head`, `tail`, `sed`, `awk`, or
`echo` commands, unless explicitly instructed or after you have verified that a
dedicated tool cannot accomplish your task. Instead, use the appropriate dedicated
tool as this will provide a much better experience for the user.
```

Transcripts also keep snapshots of the system prompt and of every tool definition that was sent.
The line above was there in 91 of the 96 snapshots taken without the reminder, and gone from 63 of
the 67 taken with it. So when Claude Code adds the reminder, it also quietly takes the warning out of
the shell tool's own description.

The general system prompt wasn't touched. Every snapshot taken under the reminder still says "Prefer
the dedicated file/search tools over shell commands when one fits." The agent was getting both
messages at once, and the later, more specific one won.

## No Grep, no Glob

The third cause has nothing to do with the reminder, and it is older. The native macOS and Linux
builds that most students used simply don't include Grep or Glob. Claude Code's Explore subagent is
told to "Use `find` via Bash for broad file pattern matching" and to "Use `grep` via Bash for
searching file contents with regex." Agents that tried to call Grep anyway got this back:

```text
Error: No such tool available: Grep. Grep is not available in this session —
search file contents with `grep` via the Bash tool instead.
```

Grep and Glob were called 43 times across the whole assignment, and they worked for just three
students: one running an old command-line version, one on Windows, and one in a handful of
desktop-app sessions. Everyone else searched with the shell, reminder or not.

## Who gets the reminder

Not every session got the reminder, and the ones that did didn't all get the same text. This is what
the assignment logs show:

- Almost every student whose main agent ran Opus 5 in auto or bypass mode got the text quoted above.
- Fable 5.1 sessions in those modes got it too.
- Opus 5.5 sessions, which only started after the deadline, got a gentler version: "You can do much
  of your work through the Bash tool when it is the simpler route … The choice is yours: prefer
  Edit or Write when a shell edit would be fragile."
- Sonnet 5 sessions never got it.
- Neither did sessions on older versions of Claude Code (2.1.215 and earlier, mostly running
  Sonnet 4 models).

Two quirks are worth knowing if you read logs yourself. Subagents follow the main session, so a
Sonnet or Haiku subagent launched from an Opus 5 session got the reminder too. And the decision is
made when a session starts: one session switched from Fable 5.1 to a different model and kept the
reminder anyway.

Whether a session gets the reminder also depends on settings that Claude Code fetches from
Anthropic's servers. The same version can behave differently on two accounts, and the behavior can
change without an update. It hasn't gone away, either. On October 5, an Opus 5 session in auto mode
on the current release, 2.1.289, still received the strict text.

## What the agents actually did with the shell

A number like 88% tells you the reminder was there. It doesn't tell you whether the shell was the
right call. So we pulled a random sample of 320 of the 7,909 calls (100 reads, 80 searches and 140
writes or edits) and read each one in context: the student's prompt, the agent's recent messages
and calls, the result, and what happened next. Each call got the first reason on our list that
applied. The readings were done by Claude reviewer agents working from a written codebook. A second
reading of 120 of the calls agreed with the first on 95% of them, and a separate blind check of 20
more matched 19.

![Reasons for using the shell in 320 sampled calls. Reading files (100 sampled calls): batching 17%, no dedicated tool 15%, no functional reason 57%, needed the shell 11%. Searching and listing (80 sampled calls): batching 1%, no dedicated tool 95%, no functional reason 1%, needed the shell 1%, other 1%. Writing and editing files (140 sampled calls): batching 67%, no dedicated tool 1%, no functional reason 13%, needed the shell 9%, other 9%. All 7,909 calls (weighted by job): batching 47%, no dedicated tool 20%, no functional reason 18%, needed the shell 8%, other 6%.](why-bash-reasons.svg "Figure 4. Why the shell was used, by the job the call did. Other covers calls that weren't really file jobs, plus the two where the student asked for the shell.")

Here are the reasons in the order we checked them, each with a typical example:

| Reason | Share of all calls | What it typically looked like |
| --- | ---: | --- |
| Not really a file job | 6% | A test run whose only file change was a log file |
| The student asked for the shell | 1% | The prompt spelled out the command |
| Workaround after a file tool failed | 0% | Never seen |
| No dedicated tool | 20% | `grep -n "renderOutline" static/app.js`, or `find . -name "*.test.ts"` |
| Needed the shell | 8% | `jq` queries over a JSONL log, `tail -n 30 server.log`, a regex rewrite across files |
| Batching | 47% | A Python patch with several replacements, then `node --check app.js`, in one call |
| No functional reason | 18% | `sed -n '120,160p' src/server.js`, or a new file written with a heredoc |

The shares are weighted to all 7,909 calls, and the commands are representative examples rather
than quotes.

The first thing that struck us was how rarely anything in the conversation prompted the choice. In
318 of the 320 calls, nobody had asked for the shell and nothing had gone wrong. Not one call came
right after a dedicated tool had failed.

Almost half the calls were batching: a file change plus a check, a test run or a server restart,
folded into a single shell command. That habit seems to come with the reminder. In sessions without
it, more than 90% of edits went through Edit or Write instead.

The calls with no functional reason look the most like the instruction itself. Of the 57 reads in
that group, 43 were a single `sed -n` line range. One Read call with an offset and a limit does
exactly the same thing, and `sed -n` happens to be one of the commands the reminder names.

Finally, one shell habit tends to lead to the next. The Edit tool refuses to change a file that the
agent hasn't opened with the Read tool. Of the 69 sampled shell edits to existing files, 44 were to
files the agent had only ever looked at through the shell. To use Edit on those, it would have needed
an extra Read first. Staying in the shell skipped that step.

## What to do about it

**If you're building an interface for agent runs,** the wall of Bash came mostly from a product
setting, so don't go rewriting your prompts over it. Our own assignment suggested
`--dangerously-skip-permissions` for headless runs, and that flag means bypass mode, so the course's
advice switched the reminder on in a lot of apps. If you want Read, Edit and Write to show up, start
headless runs with `--permission-mode acceptEdits`, or approve tools with `--allowedTools` instead of
skipping permissions. Asking for the tools by name works most of the time too: in turns where
students named Read or Edit, only 26 of 173 reads and edits still went through Bash.

**If you're reviewing what an agent did,** remember that a shell edit doesn't come with the
structured patch that the Edit tool returns. Look at the changes in the working tree, not just at the
tool calls.

**If you're measuring agent behavior from logs,** check which reminder each session received before
you compare students, models or assignments, because tool-choice statistics depend on it. You can
check your own sessions like this:

```bash
# sessions that received the reminder
grep -l '"bashFirst":true' ~/.claude/projects/*/*.jsonl
# sessions that received the gentler text
grep -l 'when it is the simpler route' ~/.claude/projects/*/*.jsonl
```

We don't know why Anthropic turned this on, and our logs can't tell us whether working through the
shell makes the agent better or worse at its job. What they do show is that a lot of what looked
like the model's own habit was the harness giving instructions. When you study an agent, the
instructions it received are part of the data.

*Based on the session logs that CS2680 students submitted with Assignment 1, from the build
sessions of 61 students, including the system reminders, prompt snapshots and tool definitions those
logs record. All numbers are aggregates, and examples are anonymized and paraphrased. This post was
drafted by Claude (Opus 5.5, in Claude Code) from the course's session-log analysis.*
