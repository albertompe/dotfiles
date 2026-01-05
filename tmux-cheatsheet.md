# Tmux cheatsheet

## Key commands

Start a new session:

```bash
tmux new -s session_name
```

Detach session:

```bash
tmux detach
```

List sessions:

```bash
tmux ls
```

Attach to a session:

```bash
tmux attach -t session_name
```

# Shortcuts

Prefix: `CTRL + b`

Reload Tmux configuration file: `prefix + r`

Detach from Tmux session: `prefix + d`

Session management:
- Create new session: `prefix + c`
- List sessions: `prefix + s`
- Switch to next session: `prefix + (`
- Switch to previous session: `prefix + )`
- Rename current session: `prefix + $`

Pane management and navigation:
- Split pane vertically: `prefix + v`
- Split pane horizontally: `prefix + b`
- Close current pane: `prefix + x`
- Switch to next pane: `prefix + o`
- Switch to previous pane: `prefix + ;`
- Maximize/restore current pane: `prefix + m`
- Switch to pane on top: `prefix + k`
- Switch to pane on bottom: `prefix + j`
- Switch to pane on left: `prefix + h`
- Switch to pane on right: `prefix + l`
- Swap current pane with main left pane: `prefix + a`

Resize panes:
- Resize pane to top: `prefix + k` (hold `CTRL` and press `k` multiple times)
- Resize pane to bottom: `prefix + j` (hold `CTRL` and press `j` multiple times)
- Resize pane to left: `prefix + h` (hold `CTRL` and press `h` multiple times)
- Resize pane to right: `prefix + l` (hold `CTRL` and press `l` multiple times)

Window management:
- Create new window: `prefix + c`
- Close current window: `prefix + &`
- Switch to next window: `prefix + n`
- Switch to previous window: `prefix + p`
- Switch to window by number: `prefix + [1-9]`
- Rename current window: `prefix + ,`
- List windows: `prefix + w`

Copy mode:
- Enter copy mode: `prefix + u`
- Exit copy mode: `q`
- Move cursor up: `k` or `UP`
- Move cursor down: `j` or `DOWN`
- Move cursor left: `h` or `LEFT`
- Move cursor right: `l` or `RIGHT`
- Page up: `PageUp`
- Page down: `PageDown`
- Start selection: `SPACE`
- Copy selection: `ENTER`
