-- default configuration
-- https://wezfurlong.org/wezterm/config/files.html

-- Pull in the wezterm API
local wezterm = require 'wezterm'
local act = wezterm.action
-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
	config = wezterm.config_builder()
end


-- status bar
wezterm.on('update-status', function(window, pane)
	-- "Wed Mar 3 08:14"
	local tab = pane:tab()
	local total_panes = '  x ' .. #(tab:panes())

	window:set_left_status(wezterm.format {
		{ Foreground = { Color = '#A6ADBA' } },
		{ Text = total_panes .. ' ' },
	})
end)


-- This function returns the suggested title for a tab.
-- It prefers the title that was set via `tab:set_title()`
-- or `wezterm cli set-tab-title`, but falls back to the
-- title of the active pane in that tab.
function tab_title(tab_info)
	local title = tab_info.tab_title
	-- if the tab title is explicitly set, take that
	if title and #title > 0 then
		return title
	end
	-- Otherwise, use the title from the active pane
	-- in that tab
	return tab_info.active_pane.title
end

wezterm.on(
'format-tab-title',
function(tab, tabs, panes, config, hover, max_width)
	local background = '#282B32'
	local foreground = '#83879F'

	local activeTabIcon = '󰧛 '

	if tab.is_active then
		background = '#000000'
		foreground = '#B7B9C7'
		activeTabIcon = '󰧚 '
	end


	local title = tab_title(tab)

	-- ensure that the titles fit in the available space,
	-- and that we have room for the edges.
	title = wezterm.truncate_right(title, max_width - 2)

	return {
		{ Background = { Color = background } },
		{ Foreground = { Color = foreground} },
		{ Text = activeTabIcon },
		{ Background = { Color = background } },
		{ Foreground = { Color = foreground } },
		{ Text = title },
	}
end
)

config.check_for_updates = false

-- This is where you actually apply your config choices

-- For example, changing the color scheme:
-- config.color_scheme = 'AdventureTime'


config.leader = { key = 'Space', mods = 'CTRL', timeout_milliseconds = 1000 }


-- PaneSelect
-- https://wezfurlong.org/wezterm/config/lua/keyassignment/PaneSelect.html

-- 36 is the default, but you can choose a different size.
-- Uses the same font as window_frame.font
-- config.pane_select_font_size=36,


config.colors = {
	compose_cursor = 'orange',

	-- The color of the split lines between panes
	split = '#5AD56A',
}


config.keys = {
	-- activate pane selection mode
	{
		key = 'o',
		mods = 'LEADER',
		action = act.PaneSelect,
		-- with numeric labels
		-- action = act.PaneSelect {
		-- 	alphabet = '1234567890',
		-- },
	},

	-- swap pane
	{
		key = 'u',
		mods = 'LEADER',
		action = act.PaneSelect {
			mode = 'SwapWithActive',
			alphabet = '1234567890',
		},
	},

	-- ShowTabNavigator
	{ key = 'i', mods = 'LEADER', action = wezterm.action.ShowTabNavigator },

	-- split-pane with vim key movements H-J-K-L
	{
		key = 'H',
		mods = 'LEADER',
		action = act.SplitPane {
			direction = 'Left',
			-- command = { args = { 'top' } },
			-- size = { Percent = 50 },
		},
	},
	{
		key = 'J',
		mods = 'LEADER',
		action = act.SplitPane {
			direction = 'Down',
		},
	},
	{
		key = 'K',
		mods = 'LEADER',
		action = act.SplitPane {
			direction = 'Up',
		},
	},
	{
		key = 'L',
		mods = 'LEADER',
		action = act.SplitPane {
			direction = 'Right',
		},
	},

	-- switch ActivatePaneDirection
	{
		key = 'h',
		mods = 'LEADER',
		action = act.ActivatePaneDirection 'Left',
	},
	{
		key = 'l',
		mods = 'LEADER',
		action = act.ActivatePaneDirection 'Right',
	},
	{
		key = 'k',
		mods = 'LEADER',
		action = act.ActivatePaneDirection 'Up',
	},
	{
		key = 'j',
		mods = 'LEADER',
		action = act.ActivatePaneDirection 'Down',
	},

	-- Toggles the zoom state of the current pane
	{
		key = 'Space',
		mods = 'LEADER',
		action = act.TogglePaneZoomState,
	},

	-- Create a new tab in the same domain as the current pane.
	-- This is usually what you want.
	{
		key = 't',
		mods = 'LEADER',
		action = act.SpawnTab 'CurrentPaneDomain',
	},

	-- rename tab
	{
		key = 'y',
		mods = 'LEADER',
		action = act.PromptInputLine {
			description = 'Enter new name for tab',
			action = wezterm.action_callback(function(window, pane, line)
				-- line will be `nil` if they hit escape without entering anything
				-- An empty string if they just hit enter
				-- Or the actual line of text they wrote
				if line then
					window:active_tab():set_title(line)
				end
			end),
		},
	},

	-- close current pane
	{
		key = 'q',
		mods = 'LEADER',
		action = wezterm.action.CloseCurrentPane { confirm = true },
	},
	{
		key = 'x',
		mods = 'LEADER',
		action = wezterm.action.QuitApplication,
	},

}

-- and finally, return the configuration to wezterm
return config

