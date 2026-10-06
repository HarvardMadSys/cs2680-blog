---
title: "Why Claude Code Used Bash Instead of Its File Tools"
date: 2026-10-06
authors: ["cs2680-staff"]
summary: "In Assignment 1, Claude Code did much of its reading, searching and editing through the shell. The session logs show why: a bash-first instruction in auto and bypass modes, a Bash tool description without its usual warning, and no Grep or Glob tools."
tags: ["agent-design", "observability", "tool-use", "session-logs"]
draft: false
toc: true
---

For Assignment 1, students built web interfaces that show what Claude Code does as it works: the
files it reads, the commands it runs, the edits it makes. Many expected their interfaces to fill
with Read, Edit and Write cards. Instead they saw `cat`, `sed -n`, heredocs and Python patch
scripts, all inside Bash cards. One of our [lessons from the
assignment](/2026/assignment1/agentic-coding-lessons/) describes an agent that made an entire bug
fix through shell commands, so the student's edit renderer never activated.

We went through the session logs that students submitted with the assignment to find out why. The
answer is mostly not in the students' prompts or in the model's own habits. Claude Code itself told
the agent to use the shell, removed the shell tool's usual warning against doing so, and in most
installations offered no dedicated search tools at all.

<!--more-->

## How much file work went through the shell

Claude Code has dedicated tools for working with files: Read, Edit and Write, and on some
installations Grep and Glob for searching. The same jobs can be done in Bash: `cat` or `sed -n` to
read, `grep` and `find` to search, and heredocs, `sed -i` or a short script to write. Across the
build sessions of 61 students, Bash did these jobs 7,909 times:

![Share of each file job done through Bash in Assignment 1 build sessions: reading files 29% (1,354 of 4,745 calls); searching and listing 97% (1,404 of 1,447 calls); writing and editing files 52% (5,151 of 9,874 calls).](why-bash-jobs.svg "Figure 1. Share of each file job that went through Bash, in the build sessions of 61 students.")

Three things in Claude Code explain most of this figure.

## An instruction to prefer the shell

When a session runs in auto mode or bypass-permissions mode, Claude Code can add a system reminder
to the conversation. In every version students used during the assignment, it read as follows
(here and below, the line breaks in quoted texts are ours):

```text
Do your work through the Bash tool wherever it can accomplish the job: read files
with cat, head, or sed -n, search with grep and find, and make file changes with
sed, heredocs, or short scripts, rather than using the dedicated Read, Edit, or
Write tools. Fall back to a dedicated tool only when Bash genuinely cannot do the
job.
```

The reminder is not secret. Claude Code writes it into the session transcript under
`~/.claude/projects/`, as an `auto_mode` record with `"bashFirst":true`, together with the exact
text the model received. Of the 7,909 shell calls above, 88% were made with this text in the
conversation.

The reminder accounts for most of the difference. Figure 2 compares calls made with the reminder in
context to calls in sessions that never received it:

![Share of each job done through Bash without the bash-first reminder versus with it in context: reading files: 8% versus 41%; writing and editing files: 8% versus 67%; reads and edits by Opus 5 main agents: 10% versus 78%; the same 22 sessions, before and after: 6% versus 82%; searching (no Grep or Glob either way): 89% versus 100%.](why-bash-reminder.svg "Figure 2. Share of each job done through Bash, in calls with no reminder (grey) and with the reminder in the conversation (crimson).")

The fourth row is the strongest evidence. In 22 sessions, the reminder arrived partway through,
usually because the student switched to auto mode. In 21 of them, the agent's use of the shell for
reading and editing went up, as Figure 3 shows. In one such session, the agent made five changes
with the Edit tool and created one file with Write; its next file operations, once the reminder
arrived, were `sed -n` reads and Python patch scripts.

![Share of reads and edits done through Bash in 22 sessions where the reminder appeared partway through. Overall 6% before and 82% after; 21 of 22 sessions went up.](why-bash-sessions.svg "Figure 3. Reads and edits done through Bash in the 22 sessions where the reminder appeared partway through. Each line is one session, before and after the reminder arrived.")

The reminder also outlasts the mode that triggered it. Once added, it stays in the conversation.
Claude Code can add an "Exited Auto Mode" notice that tells the agent to go back to the dedicated
tools, but it appeared only three times in our logs. In prompts typed in default mode while an
earlier reminder was still in the conversation, the agent did 81% of its reads and edits through
Bash, against 9% in default-mode sessions that never received it.

Agents sometimes said so themselves. When one student asked why it had used `cat` instead of the
Read tool, the agent answered that the instructions for bypass mode told it to prefer Bash. Other
agents mentioned a "Bash-first" default when they set it aside because a student had asked for Read
and Edit by name.

One student's agent found the cause and tested it. The student's app showed only Bash cards during
live runs. The agent searched the run's transcript, found the reminder, and ran the same prompt
twice. Under `--dangerously-skip-permissions`, which is bypass mode, the run used only Bash. Under
`--permission-mode acceptEdits`, the reminder was absent and the run used Read, Edit and Write. The
agent also found why the app could not have shown the cause: the stream-json output that such apps
read does not include the reminder.

## A Bash description without its warning

Every request to the model includes a description of each tool. The description of the Bash tool
normally contains this line:

```text
IMPORTANT: Avoid using this tool to run `cat`, `head`, `tail`, `sed`, `awk`, or
`echo` commands, unless explicitly instructed or after you have verified that a
dedicated tool cannot accomplish your task. Instead, use the appropriate dedicated
tool as this will provide a much better experience for the user.
```

Session transcripts also keep snapshots of the system prompt and of every tool definition sent to
the model. The line above was present in 91 of the 96 snapshots taken without the reminder, and
missing from 63 of the 67 snapshots taken with it. When Claude Code adds the reminder, it also
removes this warning from the shell tool's own description.

The general system prompt did not change. Every snapshot taken under the reminder still says
"Prefer the dedicated file/search tools over shell commands when one fits." The agent received
both messages, and the more specific one, which came later, won.

## No Grep or Glob

The third cause is older and separate from the reminder. The native macOS and Linux builds that
most students used do not offer Grep or Glob. The instructions for Claude Code's Explore subagent
say "Use `find` via Bash for broad file pattern matching" and "Use `grep` via Bash for searching
file contents with regex." When an agent tried to call Grep anyway, it was told:

```text
Error: No such tool available: Grep. Grep is not available in this session —
search file contents with `grep` via the Bash tool instead.
```

Grep and Glob were called 43 times in all, and worked for only three students: one on an old
command-line version, one on Windows, and one in a few desktop-app sessions. For everyone else,
searching meant the shell, with or without the reminder.

## Which sessions get the reminder

Not every session received the reminder, and not every session received the same text. In the
assignment logs:

- Almost every student whose main agent ran Opus 5 in auto or bypass mode got the text quoted
  above.
- Fable 5.1 sessions in those modes got it too.
- Opus 5.5 sessions, which started after the assignment deadline, got a softer version: "You can
  do much of your work through the Bash tool when it is the simpler route … The choice is yours:
  prefer Edit or Write when a shell edit would be fragile."
- Sonnet 5 sessions did not get it.
- Sessions on older versions of Claude Code (2.1.215 and earlier, mostly with Sonnet 4 models)
  never got it.

Two details matter when you read logs. Subagents follow the main session, so a Sonnet or Haiku
subagent launched from an Opus 5 session received the reminder as well. And the decision is made
when a session starts: one session that switched from Fable 5.1 to another model kept the reminder.

Whether a session receives the reminder also depends on settings that Claude Code gets from
Anthropic's servers, so the same version can behave differently for different accounts and change
over time. It has not gone away: on October 5, an Opus 5 session in auto mode on the current
release, 2.1.289, still received the strict text.

## What the shell calls did

To see what the agent actually did with the shell, we drew a random sample of 320 of the 7,909
calls (100 reads, 80 searches and 140 writes or edits) and read each one in its context: the
student's prompt, the agent's recent messages and calls, the result, and what came next. Each call
got the first reason in this list that applied. A second, independent reading of 120 of the calls
agreed with the first on 95% of them.

![Reasons for using the shell in 320 sampled calls. Reading files (100 sampled calls): batching 17%, no dedicated tool 15%, no functional reason 57%, needed the shell 11%. Searching and listing (80 sampled calls): batching 1%, no dedicated tool 95%, no functional reason 1%, needed the shell 1%, other 1%. Writing and editing files (140 sampled calls): batching 67%, no dedicated tool 1%, no functional reason 13%, needed the shell 9%, other 9%. All 7,909 calls (weighted by job): batching 47%, no dedicated tool 20%, no functional reason 18%, needed the shell 8%, other 6%.](why-bash-reasons.svg "Figure 4. Why the shell was used, by the job the call did. Other covers calls that were not really file jobs and the two where the student asked for the shell.")

The table gives the reasons in the order they were checked, with a typical example of each.

| Reason | Share of all calls | What it typically looked like |
| --- | ---: | --- |
| Not really a file job | 6% | A test run whose only file change was a log file |
| The student asked for the shell | 1% | The prompt spelled out the command |
| Workaround after a file tool failed | 0% | Never seen |
| No dedicated tool | 20% | `grep -n "renderOutline" static/app.js`, or `find . -name "*.test.ts"` |
| Needed the shell | 8% | `jq` queries over a JSONL log, `tail -n 30 server.log`, a regex rewrite across files |
| Batching | 47% | A Python patch with several replacements, then `node --check app.js`, in one call |
| No functional reason | 18% | `sed -n '120,160p' src/server.js`, or a new file written with a heredoc |

The shares are weighted to all 7,909 calls. The commands are representative examples, not quotes.

Four things stand out:

- **Nothing visible in the conversation explained the choice** in 318 of the 320 calls. No call
  followed a failure of a dedicated tool.
- **Batching is a habit the reminder enables.** Almost half the calls put a file change and a
  check, test or server restart into one shell command. Without the reminder, more than 90% of
  edits went through Edit or Write instead.
- **The calls with no functional reason look like the instruction.** Of the 57 reads in this group,
  43 were a single `sed -n` line range. That is exactly what one Read call with an offset and a
  limit does, and `sed -n` is one of the commands the reminder names.
- **One habit leads to the next.** The Edit tool will not change a file that the agent has not
  opened with the Read tool. Of the 69 sampled shell edits to existing files, 44 changed a file the
  agent had only seen through the shell. For those files, the Edit tool would have needed an extra
  Read call first. The shell did not.

## What this means

**If you build an interface for agent runs**, the Bash-heavy trajectories you saw came mostly from a
product setting, not from your prompts. The assignment suggested `--dangerously-skip-permissions`
for headless runs, which is bypass mode, so this advice turned the reminder on in many apps. To see
Read, Edit and Write calls, start headless runs with `--permission-mode acceptEdits`, or approve
tools with `--allowedTools` instead of skipping permissions. Asking for the tools by name also
works most of the time: in turns where students named the Read or Edit tool, 26 of 173 reads and
edits still went through Bash.

**If you review an agent's work**, remember that a shell edit does not produce the structured patch
that the Edit tool returns. Review the changes in the working tree, not only the tool calls.

**If you measure agent behavior from logs**, tool-choice statistics depend on this setting. Check
which reminder each session received before you compare students, models or assignments. To check
your own sessions:

```bash
# sessions that received the reminder
grep -l '"bashFirst":true' ~/.claude/projects/*/*.jsonl
# sessions that received the softer text
grep -l 'when it is the simpler route' ~/.claude/projects/*/*.jsonl
```

*Based on the session logs that CS2680 students submitted with Assignment 1: the build sessions of
61 students, and the system reminders, prompt snapshots and tool definitions that those logs
record. All numbers are aggregates; examples are anonymized and paraphrased. This post was drafted
by Claude (Opus 5.5, in Claude Code) from the course's session-log analysis.*
