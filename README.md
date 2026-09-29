# cmux setup

Portable cmux configuration for a macOS agent-focused terminal environment.
Tested with cmux 0.64.20.

This repository contains:

- the cmux workspace actions and layouts;
- Ghostty appearance settings used by cmux;
- Claude/Codex cmux hooks;
- the dynamic productivity sidebar dashboard, including a Notes card;
- the small custom notification sounds used by the setup;
- a launchd template and an installation script.

The checked-in configuration intentionally does not include live session state,
transcripts, agent prompt history, credentials, or machine-specific paths. The
Link Hub layout is preserved, but its private work URLs are represented as
`about:blank` placeholders.

## Install

Requirements:

- macOS;
- [cmux](https://cmux.com/);
- `jq`;
- Claude Code and/or Codex, if you want their hooks and agent surfaces;
- [glab](https://gitlab.com/gitlab-org/cli), authenticated, for the MR Review
  diff pane.

From a cloned checkout:

```sh
git clone https://github.com/ismaileneskirli/cmux-setup.git
cd cmux-setup
./scripts/install.sh
```

The installer backs up existing cmux and Ghostty configuration before copying
these files. It installs the dashboard as a user launch agent and reloads the
cmux configuration. Edit `config/cmux.json` after installation if you want to
replace the Link Hub placeholders with your own URLs.

## Workspace actions

The setup currently defines:

- `Coding Grid` — Claude, Codex, shell, and browser;
- `Product Delivery` — product manager, dev lead, and UAT browser;
- `Adcelerate CLI` — Claude, Pro CLI, and standard CLI surfaces;
- `Link Hub` — a multi-pane browser dashboard with safe blank placeholders;
- `MR Review` (ctrl+cmd+r) — Claude, MR page, and diff for the GitLab MR URL on
  the clipboard;
- a cmux built-in browser action.

Workspace actions use commands such as `claude`, `codex`, and `cmux-deliver`.
Install those tools separately or edit the commands for your machine.

Diffs are reviewed on demand in the built-in cmux diff viewer rather than a
live pane: press ctrl+cmd+shift+d, or run `cmux diff --last-turn` (what the
agent just changed) or `cmux diff --branch` (the whole branch against main).

## MR Review

Copy a GitLab merge request URL, then press ctrl+cmd+r, or pick MR Review from
the new-workspace menu or Command Palette. `scripts/cmux-mr-review` opens a
workspace named like `MR !42 server` in the matching local repository:

- Claude, focused, running `claude --permission-mode auto "code review and
  /babysit-mr <MR URL>"`;
- the MR page in a browser pane;
- the MR diff in the cmux diff viewer, fetched with
  `glab api projects/<project>/merge_requests/<iid>/raw_diffs`.

Map GitLab projects to local checkouts in `~/.config/cmux/mr-review.conf` (the
installer copies `config/mr-review.conf.example` there if it is missing), or
point `CMUX_MR_REVIEW_CONFIG` at another file:

```text
# <host/project-path glob>       <label>  <local repo path>
gitlab.com/my-group/*/my-server  server   ~/code/my-server
```

Anything that is not an MR URL for a listed project is rejected with a cmux
notification and an error in the launcher tab. If `glab` is missing, not
authenticated, or the diff fetch fails, the workspace still opens with Claude
and the MR page, and a notification explains why the diff is missing.
`cmux-mr-review <MR URL>` also works from any cmux terminal. Edit the script to
change the Claude prompt.

## Agents row

The top of the sidebar shows every agent session in an open tab, grouped by
what it needs from you:

- `⏸` waiting for your input (last 48h), oldest first;
- `✓` finished a turn (last 48h), newest first;
- `💤` idle or waiting for more than 48h, with the memory they use, so you can
  decide which ones to close. Nothing is closed automatically.

Click a group to see its agents and jump to one. ctrl+cmd+j jumps to the next
waiting agent and ctrl+cmd+k to the next finished one; cmux's built-in
cmd+shift+u still jumps to the latest unread notification. The same data is
available in a terminal with `cmux-agents list`.

Agent hibernation is on (`terminal.agentHibernation`): with more than 12 live
agent terminals, background agents idle for 30 minutes are paused to free
memory and resume when their tab is opened again.

## Notes card

The sidebar shows a Notes card fed by `~/.config/cmux/notes.md` (one note per
line, blank lines ignored, first 12 lines shown). The dashboard creates the file
with a starter line if it is missing and re-reads it every 10 seconds. cmux
sidebars cannot edit text inline, so tap the card header to open the file in
your default editor. To keep the notes in an Obsidian vault, replace the file
with a symlink into the vault; the card then opens the note through Obsidian's
`obsidian://open` URI instead of a plain file URL.

## Dock and Pomodoro

`dock/pomodoro.html` is an offline Pomodoro timer sized for about a third of the
Dock (Space start/pause, R reset, S skip, 1/2/3 mode, arrow keys change the
minutes). The installer copies it to `~/.config/cmux/dock/` and, only if you do
not have one yet, writes `~/.config/cmux/dock.json` from `dock/dock.json.example`.
The Dock is a cmux beta feature: turn it on in Settings > Beta Features. cmux
uses `dock.json` to seed an empty Dock; after that it restores the saved Dock.

## Claude Code spinner words

`claude/spinner-verbs.json` holds the Turkish spinner words (Demleniyor,
Kervan yolda düzülüyor, Hayırlısı bekleniyor…). It is not installed
automatically; merge its `spinnerVerbs` key into `~/.claude/settings.json`.

## Updating the setup

After changing cmux settings, back up the local files and copy the desired
configuration into this repository. Do not commit session files, API tokens,
OAuth credentials, private URLs, or absolute home-directory paths.

See [SECURITY.md](SECURITY.md) for the dashboard's local credential and
session-data behavior.
