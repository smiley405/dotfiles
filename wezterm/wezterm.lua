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


-- Chrome from tokyonight_night, the scheme nvim runs, so terminal, editor and
-- bar are one palette. comment (2.91:1) and terminal_black (1.91:1) are
-- lightened: fine as syntax, too dark as UI. AA on every surface, 3:1 non-text.
local ui = {
	bar = '#16161E',       -- bg_dark, one step under the terminal
	tab = '#292E42',       -- bg_highlight, an inactive tab
	tab_fg = '#A9B1D6',    -- fg_dark, 6.36:1 on tab
	active = '#1A1B26',    -- the terminal's own bg: the tab joins its content
	active_fg = '#C0CAF5', -- fg, 10.59:1 on active
	status = '#A9B1D6',    -- 8.52:1 on bar
	dim = '#7982AB',       -- comment, lightened to clear 4.79:1 on bar
	line = '#616A90',      -- terminal_black, lightened to 3.23:1 on the terminal
	blue = '#7AA2F7',      -- transient success (copied)
	amber = '#E0AF68',     -- a mode is armed (leader, zoom)
	ink = '#1A1B26',       -- text on blue/amber, 6.79:1 and 8.55:1
}

-- A "copied" chip on selection. wezterm fires no event when the clipboard is
-- written, so the selection bindings raise it themselves. update-status ticks
-- once a second, so the chip lives one to two.
local COPIED_TOAST_SECONDS = 2
local copied_at = nil

-- wezterm.gui exposes no default *mouse* bindings to read this back from, so it
-- is pinned to what `wezterm show-keys` reports. Recheck after a nightly bump.
local COMPLETE_SELECTION = 'ClipboardAndPrimarySelection'

local function draw_copied(window)
	local lit = copied_at ~= nil and os.time() - copied_at < COPIED_TOAST_SECONDS
	if not lit then copied_at = nil end
	-- pcall so a reworked status API costs the chip and nothing around it
	pcall(function()
		window:set_right_status(lit and wezterm.format {
			{ Background = { Color = ui.blue } },
			{ Foreground = { Color = ui.ink } },
			{ Text = ' \u{f018f} copied ' },
		} or '')
	end)
end

-- Read the selection before the action runs. An empty one earns no chip: a bare
-- click completes a selection too, and that is a click, not a copy.
local function copy_and_say(action)
	return wezterm.action_callback(function(window, pane)
		local ok, selection = pcall(function()
			return window:get_selection_text_for_pane(pane)
		end)
		-- outside the pcall and unconditional: the copy never depends on the chip
		window:perform_action(action, pane)
		if ok and selection and #selection > 0 then
			copied_at = os.time()
			draw_copied(window)
		end
	end)
end


-- status bar
wezterm.on('update-status', function(window, pane)
	-- "Wed Mar 3 08:14"
	-- ahead of the early returns: the chip must expire even in a tabless pane
	draw_copied(window)
	if not pane then return end
	local tab = pane:tab()
	-- panes such as the debug overlay aren't attached to a tab
	if not tab then return end
	local cells = {}

	-- a modal keymap with no visible mode is a guessing game
	if window:leader_is_active() then
		cells[#cells + 1] = { Background = { Color = ui.amber } }
		cells[#cells + 1] = { Foreground = { Color = ui.ink } }
		cells[#cells + 1] = { Text = ' LEADER ' }
		cells[#cells + 1] = { Background = { Color = ui.bar } }
	end

	-- Zoom hides every other pane, so the count alone reads as a lie.
	-- panes_with_info has both; there is no is_zoomed() on a pane.
	-- pcall: a tab torn down between pane:tab() and here raises "tab id 0 not
	-- found in mux". Rare, and only ever on the way out, but it is one stray
	-- error per closing window otherwise.
	local ok, infos = pcall(function() return tab:panes_with_info() end)
	if not ok then return end
	local panes, zoomed = #infos, false
	for _, info in ipairs(infos) do
		if info.is_zoomed then zoomed = true end
	end

	if zoomed then
		cells[#cells + 1] = { Foreground = { Color = ui.amber } }
		cells[#cells + 1] = { Text = ' zoom' }
	end

	-- Accent, and never dimmed: it sits left of tab 1 and both show a number,
	-- so without a colour of its own it reads as one more tab.
	cells[#cells + 1] = { Foreground = { Color = ui.blue } }
	cells[#cells + 1] = { Text = '  \u{eb23} ' .. panes .. '  ' }

	window:set_left_status(wezterm.format(cells))
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

-- An editor tab says what is in it; a terminal tab can too. Glyph names are
-- from `wezterm ls-fonts --text`, so every one of these resolves.
local PROGRAM_ICONS = {
	nvim = '\u{e62b}',
	vim = '\u{e62b}',
	lazygit = '\u{e702}',
	git = '\u{e702}',
	yazi = '\u{f07c}',
	node = '\u{e718}',
	npm = '\u{e718}',
	python = '\u{e73c}',
	python3 = '\u{e73c}',
	docker = '\u{e7b0}',
}
local SHELL_ICON = '\u{ebca}'

-- Returns the program and, when the title carried it, the name to show.
local function tab_program(tab)
	local pane = tab.active_pane
	local proc = ((pane.foreground_process_name or ''):lower():match('[^\\/]+$') or '')
		:gsub('%.exe$', '')
	if PROGRAM_ICONS[proc] then return proc, nil end

	-- Every WSL pane reports wslhost.exe, so the process says nothing there and
	-- the program names itself in the title instead -- see nvim's titlestring
	-- in nvim/lua/config/_default.lua.
	local name, rest = (pane.title or ''):match('^(%a+): (.+)$')
	if name and PROGRAM_ICONS[name:lower()] then return name:lower(), rest end
	return nil, nil
end

wezterm.on(
'format-tab-title',
function(tab, tabs, panes, config, hover, max_width)
	local background = ui.tab
	local foreground = ui.tab_fg
	-- The accent bar is a shape, not a shade: the tab surfaces differ by only
	-- 1.27:1, too little to be the only thing telling them apart.
	local edge = ' '

	if tab.is_active then
		background = ui.active
		foreground = ui.active_fg
		edge = '\u{258e}'
	elseif hover then
		foreground = ui.active_fg
	end

	local program, named = tab_program(tab)
	local icon = (program and PROGRAM_ICONS[program] or SHELL_ICON) .. ' '

	-- numbered because SHIFT+CTRL+<n> jumps to a tab
	local title = wezterm.truncate_right(named or tab_title(tab), max_width - 6)

	return {
		{ Background = { Color = background } },
		{ Foreground = { Color = tab.is_active and ui.blue or background } },
		{ Text = edge },
		{ Foreground = { Color = foreground } },
		{ Text = icon .. (tab.tab_index + 1) .. ' ' .. title .. ' ' },
	}
end
)

config.check_for_updates = false
-- to make the scrollbar visible, you might need to add settings.json this { "tui": "default" }
-- something like that in other tui app's config settings
config.enable_scroll_bar = true

-- Top, because every overlay -- tab navigator, PaneSelect, palette -- opens
-- from the top of the pane, and a bottom bar puts the tab list opposite the tabs.
config.tab_bar_at_bottom = false

-- retro draws in terminal cells and obeys the palette; fancy uses its own font
config.use_fancy_tab_bar = false

-- never hidden: leader, zoom and copied all report in this bar
config.hide_tab_bar_if_only_one_tab = false

-- tabs open and close from the keyboard, and one button is a misclick that
-- closes work
config.show_new_tab_button_in_tab_bar = false
config.show_close_tab_button_in_tabs = false
config.tab_max_width = 28

-- dimming what is unfocused is what makes the active pane obvious
config.inactive_pane_hsb = { saturation = 0.85, brightness = 0.65 }

config.window_padding = { left = 10, right = 10, top = 6, bottom = 4 }

-- a little air between rows; long log output is what this is for
config.line_height = 1.1

-- a cursor tint says the same as a beep, without the jolt
config.audible_bell = 'Disabled'
config.visual_bell = {
	fade_in_duration_ms = 60,
	fade_out_duration_ms = 180,
	target = 'CursorColor',
}

-- overlays take the palette too, not wezterm's stock blue
config.command_palette_bg_color = ui.tab
config.command_palette_fg_color = ui.active_fg
config.command_palette_rows = 12
config.char_select_bg_color = ui.tab
config.char_select_fg_color = ui.active_fg
config.pane_select_bg_color = ui.bar
config.pane_select_fg_color = ui.amber

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

-- The three ways a left button finishes a selection: drag, double click, triple
-- click. Stock bindings with copy_and_say wrapped round them; the rest of the
-- mouse keeps wezterm's defaults, which merge in around these.
--
-- Built behind pcall, not as a literal: naming an action a future wezterm has
-- dropped raises as this file loads, taking the leader table with it. Skipping
-- one restores wezterm's default, so the copy survives and only the chip goes.
local selection_bindings = {}

local function add_selection_binding(streak, build)
	local ok, action = pcall(build)
	if not ok then
		wezterm.log_warn('copied chip: no selection action for streak '
			.. streak .. ', leaving that click on its default')
		return
	end
	table.insert(selection_bindings, {
		event = { Up = { streak = streak, button = 'Left' } },
		mods = 'NONE',
		action = copy_and_say(action),
	})
end

add_selection_binding(1, function()
	return act.CompleteSelectionOrOpenLinkAtMouseCursor(COMPLETE_SELECTION)
end)
add_selection_binding(2, function() return act.CompleteSelection(COMPLETE_SELECTION) end)
add_selection_binding(3, function() return act.CompleteSelection(COMPLETE_SELECTION) end)

config.mouse_bindings = selection_bindings

config.leader = { key = 'Space', mods = 'CTRL', timeout_milliseconds = 1000 }


-- PaneSelect
-- https://wezfurlong.org/wezterm/config/lua/keyassignment/PaneSelect.html

-- 36 is the default, but you can choose a different size.
-- Uses the same font as window_frame.font
-- config.pane_select_font_size=36,


-- The ANSI palette was stock while nvim ran tokyonight, so shell output and the
-- editor disagreed on every colour. This is the same scheme wezterm ships.
config.color_scheme = 'tokyonight_night'

config.colors = {
	compose_cursor = ui.amber,

	-- a seam, not a stripe -- still over the 3:1 WCAG wants for non-text.
	-- Focus is carried by the dimming above, not by this line.
	split = ui.line,

	scrollbar_thumb = ui.tab,
	cursor_bg = ui.active_fg,
	cursor_border = ui.active_fg,
	cursor_fg = ui.active,

	tab_bar = {
		background = ui.bar,
		-- format-tab-title paints the tabs; these are the states it does not
		active_tab = { bg_color = ui.active, fg_color = ui.active_fg },
		inactive_tab = { bg_color = ui.tab, fg_color = ui.tab_fg },
		inactive_tab_hover = { bg_color = ui.tab, fg_color = ui.active_fg },
		new_tab = { bg_color = ui.bar, fg_color = ui.dim },
		new_tab_hover = { bg_color = ui.tab, fg_color = ui.active_fg },
		inactive_tab_edge = ui.bar,
	},
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

	-- LEADER p -- command palette, the searchable form of all of these
	{ key = 'p', mods = 'LEADER', action = act.ActivateCommandPalette },

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

