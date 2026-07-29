# Privacy and security

This repository intentionally excludes live cmux and browser state:

- browser profiles, cookies, imported sessions, and browsing history;
- cmux session restoration files and terminal scrollback;
- agent transcripts and `~/.config/cmux/agent-prompts.json`;
- credentials, tokens, private URLs, and absolute home-directory paths.

The dashboard runs locally and reads local Claude/Codex metadata to display
usage, context, agent state, and the latest submitted prompt in the sidebar.
For Claude usage limits, it reads the existing Claude Code OAuth credential
from the macOS Keychain and sends it only to Anthropic's official usage
endpoint. Credentials and generated sidebar contents remain on the local
machine and are not written to this repository.

The cmux hooks can send agent lifecycle events to the local cmux socket. As
with any dotfiles repository, inspect scripts and configuration before
installing, especially when using a fork.

Before publishing updates, search the diff for credentials, private hostnames,
absolute home-directory paths, and generated prompt/session data.
