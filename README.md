# cmux setup

Portable cmux configuration for a macOS agent-focused terminal environment.

This repository contains:

- the cmux workspace actions and layouts;
- Ghostty appearance settings used by cmux;
- Claude/Codex cmux hooks;
- the dynamic productivity sidebar dashboard;
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
- Claude Code and/or Codex, if you want their hooks and agent surfaces.

From a cloned checkout:

```sh
./scripts/install.sh
```

The installer backs up existing cmux and Ghostty configuration before copying
these files. It installs the dashboard as a user launch agent and reloads the
cmux configuration. Edit `config/cmux.json` after installation if you want to
replace the Link Hub placeholders with your own URLs.

## Workspace actions

The setup currently defines:

- `Coding Grid` — Claude, Codex, Hunk, shell, and browser;
- `Product Delivery` — product manager, dev lead, Hunk, and UAT browser;
- `Adcelerate CLI` — Claude, Pro CLI, and standard CLI surfaces;
- `Link Hub` — a multi-pane browser dashboard with safe blank placeholders;
- a cmux built-in browser action.

Workspace actions use commands such as `claude`, `codex`, `hunk`, and
`cmux-deliver`. Install those tools separately or edit the commands for your
machine.

## Updating the setup

After changing cmux settings, back up the local files and copy the desired
configuration into this repository. Do not commit session files, API tokens,
OAuth credentials, private URLs, or absolute home-directory paths.
