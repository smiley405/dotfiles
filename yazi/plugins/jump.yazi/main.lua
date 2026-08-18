-- Every jump yazi ships is anchored to the cwd, so none reach the ancestor you
-- launched under or a sibling you have never visited. Ancestors come from the
-- path itself, the rest from fd below the repo root so gitignored trees stay
-- out. Ordered by distance, or a monorepo is unbrowsable.

local SELF = "Jump"

-- tokyonight_night, the palette theme.toml already runs
local DIM, ANCESTOR, CHILD, OFF = "\27[38;2;86;95;137m", "\27[38;2;122;162;247m", "\27[38;2;125;207;255m", "\27[0m"

local FZF = {
	"--ansi", "--no-multi", "--scheme=path", "--delimiter", "\t", "--with-nth", "1", "--accept-nth", "2",
	"--layout=reverse", "--info=inline-right", "--border=rounded", "--border-label", " jump ",
	"--prompt", "❯ ", "--pointer", "▌", "--cycle", "--header-first",
	"--preview", "fd --base-directory {2} --max-depth 1 --color always",
	"--preview-window", "right,45%,border-left",
	"--color", "fg:#a9b1d6,bg:-1,hl:#7dcfff,fg+:#c0caf5,bg+:#292e42,hl+:#7dcfff,gutter:-1,"
		.. "info:#565f89,border:#616a90,label:#7aa2f7,prompt:#7aa2f7,pointer:#bb9af7,header:#565f89,spinner:#e0af68",
}

local cwd = ya.sync(function() return cx.active.current.cwd end)

local function notify(content, level)
	ya.notify { title = SELF, content = content, timeout = 5, level = level or "error" }
end

local function home()
	local h = os.getenv("HOME") or os.getenv("USERPROFILE")
	return h ~= "" and h or nil
end

local function depth(path) return select(2, path:gsub("[/\\]", "")) end

local function under(path, dir)
	return #path > #dir + 1 and path:sub(1, #dir) == dir and path:sub(#dir + 1, #dir + 1):match("[/\\]") ~= nil
end

-- dim everything but the last component, so the eye lands on the name
local function paint(marker, colour, path)
	local parent, name = path:match("^(.*[/\\])([^/\\]+)$")
	return string.format("%s%s%s %s%s%s%s", colour, marker, OFF, DIM, parent or "", OFF, name or path)
end

local function ancestors(url)
	local t, it = {}, url.parent
	while it do
		t[#t + 1], it = tostring(it), it.parent
	end
	return t
end

local function root_of(dir)
	local output = Command("git")
		:arg({ "rev-parse", "--show-toplevel" })
		:cwd(dir)
		:stdout(Command.PIPED)
		:stderr(Command.NULL)
		:output()

	local root = output and output.status.success and output.stdout:gsub("%s+$", "")
	return root ~= "" and root or dir
end

local function below(root)
	local output, err = Command("fd")
		:arg({ "--type", "d", "--hidden", "--absolute-path", "--color", "never", "--exclude", ".git" })
		:cwd(root)
		:stdout(Command.PIPED)
		:stderr(Command.NULL)
		:output()
	if not output then
		return nil, Err("Failed to run `fd`, error: %s", err)
	end

	local t = { root }
	for line in output.stdout:gmatch("[^\r\n]+") do
		t[#t + 1] = line:gsub("[/\\]+$", "")
	end
	return t
end

-- ancestors, then what is under the cwd, then the repo shallowest-first
local function entries(here, root)
	local rows, seen = {}, { [here] = true }
	local hometilde = home()

	for _, path in ipairs(ancestors(cwd())) do
		seen[path] = true
		local shown = hometilde and path:sub(1, #hometilde) == hometilde and "~" .. path:sub(#hometilde + 1) or path
		rows[#rows + 1] = { paint("↑", ANCESTOR, shown), path }
	end

	local rest, err = below(root)
	if not rest then
		return nil, err
	end

	local mine, theirs = {}, {}
	for _, path in ipairs(rest) do
		if not seen[path] then
			seen[path] = true
			local into = here ~= root and under(path, here) and mine or theirs
			into[#into + 1] = path
		end
	end
	for _, group in ipairs({ mine, theirs }) do
		table.sort(group, function(a, b)
			local da, db = depth(a), depth(b)
			return da == db and a < b or da < db
		end)
	end

	-- root-relative, so what you type is what you see; the marker carries depth
	local function relative(path) return under(path, root) and path:sub(#root + 2) or path end
	for _, path in ipairs(mine) do
		rows[#rows + 1] = { paint("↓", CHILD, relative(path)), path }
	end
	for _, path in ipairs(theirs) do
		rows[#rows + 1] = { paint(" ", OFF, relative(path)), path }
	end
	return rows
end

local function pick(rows, here, header)
	local lines = {}
	for _, row in ipairs(rows) do
		lines[#lines + 1] = string.format("%s\t%s", row[1], row[2])
	end

	local permit = ui.hide()
	local child, err = Command("fzf"):arg(FZF):arg({ "--header", header }):cwd(here)
		:stdin(Command.PIPED)
		:stdout(Command.PIPED)
		:spawn()
	if not child then
		permit:drop()
		return nil, Err("Failed to start `fzf`, error: %s", err)
	end

	child:write_all(table.concat(lines, "\n"))
	child:flush()

	local output, err = child:wait_with_output()
	permit:drop()

	if not output then
		return nil, Err("Cannot read `fzf` output, error: %s", err)
	elseif output.status.code == 130 then
		return nil, nil
	elseif not output.status.success then
		return nil, Err("`fzf` exited with error code %s", output.status.code)
	end
	return output.stdout:gsub("[\r\n]+$", ""), nil
end

return {
	entry = function()
		ya.emit("escape", { visual = true })

		local dir = cwd()
		if dir.scheme.is_virtual then
			return notify("Not supported under virtual filesystems", "warn")
		end

		local here = tostring(dir)
		local root = root_of(here)
		local rows, err = entries(here, root)
		if not rows then
			return notify(tostring(err))
		end

		local target, err = pick(rows, here, string.format("%d directories  ·  %s", #rows, root))
		if err then
			return notify(tostring(err))
		elseif target and target ~= "" then
			ya.emit("cd", { Url(target), raw = true })
		end
	end,
}
