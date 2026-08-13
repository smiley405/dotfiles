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
	if not pane then return end
	local tab = pane:tab()
	-- panes such as the debug overlay aren't attached to a tab
	if not tab then return end
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
local function tab_title(tab_info)
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
-- to make the scrollbar visible, you might need to add settings.json this { "tui": "default" }
-- something like that in other tui app's config settings
config.enable_scroll_bar = true

-- On Windows, start straight in WSL Ubuntu instead of cmd.exe. Everywhere else
-- (linux/macos) this is a no-op and the native login shell is used.
if wezterm.target_triple:find('windows') then
	config.wsl_domains = {
		{
			name = 'WSL:Ubuntu',
			distribution = 'Ubuntu',
			-- start in the linux $HOME rather than /mnt/c/Users/...
			default_cwd = '~',
		},
	}
	config.default_domain = 'WSL:Ubuntu'
end

-- This is where you actually apply your config choices

-- For example, changing the color scheme:
-- config.color_scheme = 'AdventureTime'


-- Pinky + thumb, and pressed more than anything else here, so it cannot be a
-- two-modifier claw. nvim gives up <C-Space> for it -- see config/cmp.lua.
-- A split or tab inherits the pane's domain, never what is actually running in
-- it: `cmd.exe` typed at a WSL prompt still splits into bash, and `wsl` typed at
-- a cmd prompt still splits into cmd. wezterm cannot see inside the VM -- every
-- WSL pane reports wslhost.exe -- but that is the whole trick, since a windows
-- program running there reports its own name instead.
local function parent_domain(pane)
	local proc = (pane:get_foreground_process_name() or ''):lower()
	local base = proc:match('[^\\/]+$') or ''
	if base == 'wslhost.exe' or base == 'wsl.exe' then
		return { DomainName = 'WSL:Ubuntu' }
	end
	return { DomainName = 'local' }
end

local function split_like_parent(direction)
	return wezterm.action_callback(function(window, pane)
		window:perform_action(act.SplitPane {
			direction = direction,
			command = { domain = parent_domain(pane) },
		}, pane)
	end)
end

local function tab_like_parent()
	return wezterm.action_callback(function(window, pane)
		window:perform_action(act.SpawnTab(parent_domain(pane)), pane)
	end)
end

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


-- Leader is CTRL+Space. The pane keys mirror vim's <C-w> window prefix, so
-- LEADER h is what <C-w>h is in vim; the odd ones out are marked.
config.keys = {
	-- LEADER h/j/k/l -- move between panes
	{ key = 'h', mods = 'LEADER', action = act.ActivatePaneDirection 'Left' },
	{ key = 'j', mods = 'LEADER', action = act.ActivatePaneDirection 'Down' },
	{ key = 'k', mods = 'LEADER', action = act.ActivatePaneDirection 'Up' },
	{ key = 'l', mods = 'LEADER', action = act.ActivatePaneDirection 'Right' },

	-- LEADER s / LEADER v -- split below / right
	{ key = 's', mods = 'LEADER', action = act.SplitPane { direction = 'Down' } },
	{ key = 'v', mods = 'LEADER', action = act.SplitPane { direction = 'Right' } },

	-- LEADER H/J/K/L -- split toward any edge. No vim equivalent; shifted so
	-- the letter still names the direction.
	{ key = 'H', mods = 'LEADER', action = act.SplitPane { direction = 'Left' } },
	{ key = 'J', mods = 'LEADER', action = act.SplitPane { direction = 'Down' } },
	{ key = 'K', mods = 'LEADER', action = act.SplitPane { direction = 'Up' } },
	{ key = 'L', mods = 'LEADER', action = act.SplitPane { direction = 'Right' } },

	-- LEADER o -- zoom. "only" in vim, though <C-w>o is final and this toggles.
	{ key = 'o', mods = 'LEADER', action = act.TogglePaneZoomState },

	-- LEADER w -- pick a pane
	{ key = 'w', mods = 'LEADER', action = act.PaneSelect },

	-- LEADER x -- exchange with the pane picked
	{
		key = 'x',
		mods = 'LEADER',
		action = act.PaneSelect {
			mode = 'SwapWithActive',
			alphabet = '1234567890',
		},
	},

	-- LEADER q -- close this pane
	{ key = 'q', mods = 'LEADER', action = act.CloseCurrentPane { confirm = true } },

	-- LEADER t/T/i/r -- tabs. No vim equivalent.
	{ key = 't', mods = 'LEADER', action = act.SpawnTab 'CurrentPaneDomain' },

	-- LEADER T -- a tab in the native domain. CurrentPaneDomain inherits and never
	-- switches, so on windows every tab descends from the WSL default; this is the
	-- keyboard way out, and how a windows nvim's <leader>- reaches yazi-wez.ps1.
	{ key = 'T', mods = 'LEADER', action = act.SpawnTab { DomainName = 'local' } },
	{ key = 'i', mods = 'LEADER', action = act.ShowTabNavigator },
	{
		key = 'r',
		mods = 'LEADER',
		action = act.PromptInputLine {
			description = 'Enter new name for tab',
			action = wezterm.action_callback(function(window, pane, line)
				-- line is nil on escape, '' if they just hit enter
				if line then
					window:active_tab():set_title(line)
				end
			end),
		},
	},

	-- LEADER Q, not x: x is <C-w>x to a vim hand, and a no-prompt kill one key
	-- from q is not what that finger expects.
	{
		key = 'Q',
		mods = 'LEADER',
		action = act.InputSelector {
			title = 'Quit wezterm?',
			choices = {
				{ label = 'no, stay' },
				{ label = 'yes, quit everything' },
			},
			action = wezterm.action_callback(function(window, pane, _id, label)
				if label == 'yes, quit everything' then
					window:perform_action(act.QuitApplication, pane)
				end
			end),
		},
	},
}

-- and finally, return the configuration to wezterm
-- Splits and tabs follow the program in the pane rather than the pane's domain.
-- Windows only: elsewhere there is just the one domain, so it would be a no-op.
if wezterm.target_triple:find('windows') then
	local dirs = { s = 'Down', v = 'Right', H = 'Left', J = 'Down', K = 'Up', L = 'Right' }
	for _, k in ipairs(config.keys) do
		if k.mods == 'LEADER' then
			if dirs[k.key] then
				k.action = split_like_parent(dirs[k.key])
			elseif k.key == 't' then
				k.action = tab_like_parent()
			end
		end
	end
end

return config

