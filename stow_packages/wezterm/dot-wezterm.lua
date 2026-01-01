-- Pull in the wezterm API
local wezterm = require 'wezterm'

--This will hold the configuration
local config = wezterm.config_builder()

-- Application behaviour
config.automatically_reload_config = true
config.check_for_updates = false

-- Window configuration
config.initial_cols = 120
config.initial_rows = 28
config.window_decorations = "RESIZE"
config.window_close_confirmation = "AlwaysPrompt"
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false
config.window_padding = {
    left = 8,
    right = 8,
    top = 2,
    bottom = 2,
}

-- Font
config.font_size = 12
config.adjust_window_size_when_changing_font_size = false
config.font = wezterm.font('JetBrains Mono', { weight = 'Regular' })

-- Cursor
config.default_cursor_style = "SteadyBar"

-- Color scheme selection based on WEZTERM_THEME environment variable
local themes = {
	nord = "Nord (Gogh)",
	onedark = "One Dark (Gogh)",
}
config.window_background_opacity = 1
local success, stdout, stderr = wezterm.run_child_process({ os.getenv("SHELL"), "-c", "printenv WEZTERM_THEME" })
if not success then
    wezterm.log_error("Failed to get WEZTERM_THEME environment variable: " .. stderr)
    wezterm.log_info("Defaulting to onedark theme")
    stdout = "onedark" -- Default to onedark theme if env var is not set
end
local selected_theme = stdout:gsub("%s+", "") -- Trim whitespace/newline
config.color_scheme = themes[selected_theme]

-- Do not skip close pane confirmation
config.skip_close_confirmation_for_processes_named = {}

-- Keybindings
config.keys = {
    -- Create a new horizontal split and run your default program inside it
    {
        key = 'd',
        mods = 'CMD',
        action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
    },
    -- Create a new vertical split and run your default program inside it
    {
        key = 'd',
        mods = 'CMD|SHIFT',
        action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' },
    },
    -- Move between panes using arrow keys
    {
        key = 'LeftArrow',
        mods = 'OPT | CMD',
        action = wezterm.action.ActivatePaneDirection 'Left',
    },
    {
        key = 'RightArrow',
        mods = 'OPT | CMD',
        action = wezterm.action.ActivatePaneDirection 'Right',
    },
    {
        key = 'UpArrow',
        mods = 'OPT | CMD',
        action = wezterm.action.ActivatePaneDirection 'Up',
    },
    {
        key = 'DownArrow',
        mods = 'OPT | CMD',
        action = wezterm.action.ActivatePaneDirection 'Down',
    },
    -- Navigate between panes using hjkl keys
    {
        key = 'h',
        mods = 'OPT | CMD',
        action = wezterm.action.ActivatePaneDirection 'Left',
    },
    {
        key = 'l',
        mods = 'OPT | CMD',
        action = wezterm.action.ActivatePaneDirection 'Right',
    },
    {
        key = 'k',
        mods = 'OPT | CMD',
        action = wezterm.action.ActivatePaneDirection 'Up',
    },
    {
        key = 'j',
        mods = 'OPT | CMD',
        action = wezterm.action.ActivatePaneDirection 'Down',
    },
    -- Close current pane
    {
        key = 'w',
        mods = 'OPT | CMD',
        action = wezterm.action.CloseCurrentPane { confirm = true },
  },
}

-- URLs in Markdown files are not handled properly by default
-- Source: https://github.com/wez/wezterm/issues/3803#issuecomment-1608954312
config.hyperlink_rules = {
  -- Matches: a URL in parens: (URL)
  {
    regex = '\\((\\w+://\\S+)\\)',
    format = '$1',
    highlight = 1,
  },
  -- Matches: a URL in brackets: [URL]
  {
    regex = '\\[(\\w+://\\S+)\\]',
    format = '$1',
    highlight = 1,
  },
  -- Matches: a URL in curly braces: {URL}
  {
    regex = '\\{(\\w+://\\S+)\\}',
    format = '$1',
    highlight = 1,
  },
  -- Matches: a URL in angle brackets: <URL>
  {
    regex = '<(\\w+://\\S+)>',
    format = '$1',
    highlight = 1,
  },
  -- Then handle URLs not wrapped in brackets
  {
    -- Before
    --regex = '\\b\\w+://\\S+[)/a-zA-Z0-9-]+',
    --format = '$0',
    -- After
    regex = '[^(]\\b(\\w+://\\S+[)/a-zA-Z0-9-]+)',
    format = '$1',
    highlight = 1,
  },
  -- implicit mailto link
  {
    regex = '\\b\\w+@[\\w-]+(\\.[\\w-]+)+\\b',
    format = 'mailto:$0',
  },
}

-- Finally, return the configuration to weztern
return config

