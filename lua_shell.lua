-- lua util functions

Util = {}

--[[

local n_args = #arg

-- [-2] = "lua"
-- [-1] = "-la"
-- [ 0] = "script.lua"
-- [ 1] = arg1
-- [ 2] = arg2

-- print any arguments
printf("lua args(%d):", n_args)

for k, v in pairs(arg) do
	print(("arg[%d] = %s"):format(k, v))
end

print("\n\n\n")
]]

-- sprintf
function sprintf(fmt, ...)
	
	if (type(fmt) ~= "string") then
		return fmt
	end
	
	-- replace %S with "%s"
	local expanded_fmt = fmt:gsub("%%S", "\"%%s\"")

	return expanded_fmt:format(...)
end

-- printf
function printf(fmt, ...)

	print(sprintf(fmt, ...))
end

-- assertf
function assertf(f, fmt, ...)
	if (f) then
		return f
	end
	if (nil == fmt) then
		fmt = "assert failure"
	end
	
	-- error level 2
	error(sprintf(fmt, ...), 2)
end

-- assert type
function assertt(t, typ_s, fmt, ...)
	assertf(type(typ_s) == "string", "illegal non-string type in assertt()")
	if (type(t) == typ_s) then
		return
	end
	if (nil == fmt) then
		fmt = sprintf("assert type failure, expected %S, got %S", typ_s, type(t))
	end
	
	error(sprintf(fmt, ...), 2)
end

-- errorf	
function errorf(fmt, ...)
	if (nil == fmt) then
		fmt = "<missing errorf() fmt>"
	end
	
	error(sprintf(fmt, ...), 1)
end

--[[
function printt(fmt, ...)
	
	assert(type(fmt) == "string")
	
	local t = {...}
	assert(type(t) == "table")

	local res_t = {}
	
	for _, v in ipairs(t) do
		res_t[v] = true
	end

	return res_t
end
]]

-- exec
shell = {}
setmetatable(shell, {__index =
	function(t, func)
		-- print(("_lut %s()"):format(tostring(func)))
		local shell_fn = func.." "
		return	function (...)
			return os.execute(shell_fn..table.concat({...}," "))
		end
	end})

-- binary exec
bshell = {}
setmetatable(bshell, {__index =
	function(t, func)
		-- print(("_lut %s()"):format(tostring(func)))
		local shell_fn = func.." "
		return	function (...)
			return (tonumber(os.execute(shell_fn..table.concat({...}," "))) == 0)
		end
	end})

-- piped SINGLE-line res
pshell = {}
setmetatable(pshell, {__index =
	function(t, func)
		-- print(("_lut %s()"):format(tostring(func)))
		local shell_fn = func.." "
		return	function (...)
			-- return shell_fn..table.concat({...}," ")
			return io.popen(shell_fn..table.concat({...}," ")):read("*l")
		end
	end})

-- piped MULTI-line res, returned as table
tshell = {}
setmetatable(tshell, {__index =
	function(t, func)
		-- print(("_lut %s()"):format(tostring(func)))
		local shell_fn = func.." "
		return	function (...)
			local input_t = {...}
			if (#input_t == 0) then
				return {}
			end
			local arg_s = shell_fn..table.concat(input_t, " ")
			local f = io.popen(arg_s, 'r')
			assert(f)
			local ln_t = {}
			f:read("*a"):gsub("([^\n]*)\n", function(ln) table.insert(ln_t, ln) end)
			return ln_t
		end
	end})

-- piped REAL_TIME per-line callback
fshell = {}
setmetatable(fshell, {__index =
	function(t, func)
		-- print(("_lut %s()"):format(tostring(func)))
		local shell_fn = func.." "
		if (func == "_") then
			shell_fn = ""
		end
		
		return function (...)
			local arg_t = {...}
			assert((type(arg_t)=="table") and (#arg_t >= 1))
			local callback_fn = arg_t[#arg_t]
			assert(type(callback_fn)=="function")
			local f = io.popen(shell_fn..table.concat(arg_t," ", 1, #arg_t -1), "r")
			for ln in f:lines() do
				callback_fn(ln)
			end
			return true
		end
	end})

function Util.GetPlatform()
	-- get linux/osx platform
	local osLUT = {Linux = "linux", Darwin = "osx"}
	local plat = osLUT[pshell.uname("-s")]
	assertf(plat, "unknown platform!")
	return plat
end

function Util.GetArch()
	-- get 32/64-bit architecture
	local archLUT = {i386 = 32, i486 = 32, i686 = 32, x86_64 = 64}
	-- works for both Debian and OSX
	local arch = archLUT[pshell.uname("-m")]
	assertf(arch, "unknown CPU architecture!")
	return arch
end

function Util.GetCPUCores()
	local n_cores
	
	if (Util.GetPlatform() == "osx") then
		-- mac
		local cores_s = pshell.sysctl("-n", "hw.ncpu")
		assert("string" == type(cores_s))
		n_cores = tonumber(cores_s)
		assert(n_cores >= 1)
	else
		-- linux
		local _, _, cores_s = table.concat(tshell.lscpu(""), '\n'):find("CPU%(s%)%:%s+([^\n]+)")
		assert("string" == type(cores_s))
		n_cores = tonumber(cores_s)
		assert(n_cores >= 1)
	end

	return n_cores
end

-- get one terminal character
function getkey(msg)
	
	if (msg) then
		io.write(msg .. " ")
	end
	
	shell.stty("raw")
	local k = io.read(1)
	shell.stty("sane")
	return k
end

function getline(msg)
	
	if (msg) then
		io.write(msg .. " ")
	end
	
	local s = io.read("*l")
	
	return s
end

function shexdump(str)

	local h_s = ""
	
	-- for _, n in ipairs(table.pack(str:byte(1, #str))) do
	for _, n in ipairs({str:byte(1, #str)}) do
	
		h_s = h_s .. string.format("%02x ", n)
	end
	
	return h_s
end

function hexdump(str)

	print(shexdump(str), "\n")
end

function hashset(t)
	assert(t)
	assert(type(t) == "table")

	local res_t = {}
	
	for _, v in ipairs(t) do
		res_t[v] = true
	end

	return res_t
end

---- COLOR TERMINAL ------------------------------------------------------------

term = {}
setmetatable(term, {__index =
	function(t, func_s)
		-- print(("_lut %s()"):format(tostring(func)))
		assertf(type(func_s) == "string", "term func is not string")
		local arg_f = func_s
		-- local prefix_s = "\x1b["		-- this hex DOESN'T WORK on Lua 5.1
		local prefix_s = "\027["
		local _lut = {	black = 30, red = 31, green = 32, yellow = 33, blue = 34, magenta = 35, cyan = 36, white = 37,
				bg_black = 40, bg_red = 41, bg_green = 42, bg_yellow = 43, bg_blue = 44, bg_magenta = 45, bg_cyan = 46, bg_white = 47,
				reset = 0, bright = 1, dim = 2, underscore = 4, blink = 5, reverse = 7, hidden = 8,
				bold = 1, underline = 4,
				clear = "2J", clearline = "2K", home = "H", up = "A", down = "B", getpos = "6n", setpos = "%d;%df",
	
				}
		
		return function (...)
			
			local arg_t = {...}
			
			if ("ismeta" == arg_f) then
				
				local test_s = arg_t[1]
				
				if (type(test_s) ~= "string") then
					return false
				else
					return (test_s:byte(1, 2) == prefix_s:byte(1, 2))
				end

			elseif ("getpos" == arg_f) then
				-- query
				io.write(prefix_s,_lut.query_cursor_pos)
				io.flush()
				-- get result
				local res = ""
				io.read(2)
				
				repeat
					local c = io.read(1) 
					printf(" 0x%02x hu ", c:byte())
					
					res = res .. c
					
				until ("R" == c)
				
				local x, y = res:match("(%d+);(%d+)R")
				
				return x or -1, y or -1
				
			elseif ("setpos" == arg_f) then
			
				local pos_s = (_lut.setpos):format(arg_t[1], arg_t[2])
				
				return prefix_s .. pos_s
			end
			
			local code = _lut[arg_f]
			assertf(code, "illegal code path in term() meta function %S", tostring(arg_f))
			
			if (type(code) == "number") then
				return prefix_s .. code .. "m"
			else
				return prefix_s .. code
			end
		end
	end})

---- Log class -----------------------------------------------------------------

local
function MakeLog()

	m_Timestamp = nil
	m_File = nil

	local
	function Init(fn, timestamp_s)
		m_File = io.open(fn, "w+")
		assert(m_File)
		m_File:setvbuf("line")
		m_Timestamp = timestamp_s
	end

	local
	function GetTimestamp()
		if (not m_Timestamp) then
			return ""
		else
			return os.date(m_Timestamp)
		end
	end
	
	local
	function Append(fn, timestamp_s)
		m_File = io.open(fn, "a+")
		assertf(m_File, "can't open %S", fn)
		m_File:setvbuf("line")
		m_Timestamp = timestamp_s
		m_File:write("********************************************************************************\n")
		m_File:write("***********                        NEW SESSION                       ***********\n")
		m_File:write("********************************************************************************\n")
		m_File:write(sprintf("LUA VERSION = %S\n", _VERSION))
	
	end

	local
	function SetTimestamp(timestamp_s)
		-- "%H:%M:%S > "
		local old_ts = m_Timestamp
		m_Timestamp = timestamp_s
		return old_ts
	end

	-- generic Log function
	local
	function f(fmt, ...)
		if (not fmt) then
			return
		end
		
		local ln = sprintf(fmt, ...)
		
		if (m_File) then
			m_File:write(GetTimestamp(), ln, "\n")
		end
		
		print(ln)
	end
	
	-- log only to file
	local
	function ToFile(fmt, ...)
		
		if (not fmt) or (not m_File) then
			return
		end
		
		local ln = sprintf(fmt, ...)
		
		m_File:write("FONLY ", GetTimestamp(), ln, "\n")
		
		m_File:flush()
	end
	
	local
	function Color(...)

		local arg_t = {...}
		local full_s = ""
		local print_t = {}
		
		for _, v in ipairs(arg_t) do
			
			full_s = full_s .. v
			
			if (not term.ismeta(v)) then
				-- non-meta argument
				table.insert(print_t, v)
			end
		end
		
		-- log printable line only to file
		if (#print_t > 0) then
			ToFile(unpack(print_t))
		end
		
		-- output full (color) line and reset
		io.write(full_s, "\n", term.reset())
	end

	local
	function ColorRaw(...)
		-- (don't write to file)

		local arg_t = {...}
		local full_s = ""
		
		for _, v in ipairs(arg_t) do
			full_s = full_s .. v
		end
		
		-- output full (color) line and reset
		io.write(full_s, "\n", term.reset())
	end
	
	return
	{
		Init = Init,
		Append = Append,
		Update = Append,
		Session = Append,
		SetTimestamp = SetTimestamp,
		f = f,
		ToFile = ToFile,
		Color = Color,
		Colour = Color,
		ColorRaw = ColorRaw
	}
end

Log = MakeLog()

---- Dump (keyed) Table --------------------------------------------------------

function DumpTable(name, t)

	if (type(t) ~= "table") and (type(name) == "table") then
		-- forgot name?
		local tmp = t
		t = name
		name = tmp or "<unnamed table>"
	end

	Log.f("Dumping table %S", tostring(name))
	
	if (type(t) ~= "table") then
		Log.f("can't dump non-table %S (type %s)", tostring(t), type(t))
		return
	end
	
	local co = coroutine.create(	function(init_t)
					
						local
						function TraverseTab(t, indent)
							for k, v in pairs(t) do
								coroutine.yield(indent, k, v)
								
								if (type(v) == "table") then
									-- recurse with indent
									TraverseTab(v, indent + 1)
								end
							end
						end
						
						-- fist call
						TraverseTab(init_t, 0)
						return nil		-- done
					end)
	
	while (true) do
		local ok, indent, k, v = coroutine.resume(co, t)
		if (not (ok and indent)) then
			break
		end
		 
		Log.f(" %s [%s] = %s", string.rep("  ", indent), tostring(k), tostring(v))
	end
end

---- Stop Watch ----------------------------------------------------------------

function Util.NewStopWatch()

	local m_TimeStart = os.time()

	local
	function Reset()
		m_TimeStart = os.time()
	end

	local
	function Start()
		m_TimeStart = os.time()
	end

	local
	function Elapsed()
		local dt = os.difftime(os.time() - m_TimeStart)
		return dt
	end
	
	local
	function Dump(prefix_s)
	
		local dt = os.difftime(os.time() - m_TimeStart)
		
		Log.f("%s = %d secs", tostring(prefix_s), dt)
	end
	
	return
	{
		Reset = Reset,
		Start = Start,
		Elapsed = Elapsed,
		Dump = Dump,
	}
end

---- Escape Path ---------------------------------------------------------------

function Util.EscapePath(fn)

	assertf(type(fn) == "string", "illegal Util.EscapePath(%S)", tostring(fn))
	
	-- unescape to prevent double-escape
	local unesc_fn = fn:gsub("\\(.)", "%1")
	
	-- brute force since not all chars need escaping but reliable
	local res = unesc_fn:gsub(".",
			function(c)
				return '\\' .. c
			end)
	
	return res
end

---- Normalize Path ------------------------------------------------------------

function Util.NormalizePath(fpath, base_path, override_t)

	-- can use --canonicalize (-f)
	--   readlink -f $PATH
	assert(type(fpath) == "string")
	if (not base_path) then
		base_path = os.getenv("PWD") .. "/"
	end
	
	if (not override_t) then
		override_t = {}
	end
	
	local solved = fpath:gsub('^(%./)', base_path)
	
	solved = fpath:gsub('^(~/)', os.getenv("HOME") .. "/")
	
	local err_f
	solved = solved:gsub('%$([A-Z][A-Z0-9_]*)',
					function(envar)
						if (override_t[envar]) then
							return override_t[envar]
						end
						
						envar = os.getenv(envar)
						err_f = err_f or (not envar)
						return envar
					end)
	if (not err_f) then
		return solved
	end
end

---- Stat File with optional r/w/x flag ----------------------------------------

function Util.StatFile(fn, flag_s)

	assertf(type(fn) == "string", "illegal Util.StatFile(%S)", tostring(fn))
	
	-- resolve any env vars
	-- fn = Util.NormalizePath(fn)
	
	-- (redirects access denied error to null)
	local access_s = pshell.stat('--format="%A"', fn, '2>/dev/null') or "----------"
	assertf(access_s, "Util.StatFile(%S)", tostring(fn))
	
	local root_f = ("root" == os.getenv("USER"))
	if (root_f) then
		access_s = access_s:sub(2, 4)
	else
		access_s = access_s:sub(8, 10)
	end
	
	if (not flag_s) then
		-- return as "rwx" string
		return access_s
	else
		assertf(type(flag_s) == "string", "illegal flag_s in Util.StatFile()")

		-- test read|write|exec
		return (access_s:match(flag_s) ~= nil)
	end
end

---- File Exists ? -------------------------------------------------------------

function Util.FileExists(fn)
	
	assertf(type(fn) == "string", "Util.FileExists(%S) illegal fn", tostring(fn))
	
	local esc_fn = Util.EscapePath(fn)
	
	local exists_f
	
	if (_VERSION ~= "Lua 5.1") then
		-- lua 5.2, 5.3
		exists_f = (shell.test("-f", esc_fn) == true)
	else
		exists_f = (shell.test("-f", esc_fn) == 0)
	end
	
	return exists_f
end

---- Dir Exists ? --------------------------------------------------------------

function Util.DirExists(fn)
	
	assertf(type(fn) == "string", "Util.DirExists(%S) illegal fn", tostring(fn))
	
	local esc_fn = Util.EscapePath(fn)
	
	local exists_f
	
	if (_VERSION ~= "Lua 5.1") then
		-- for 5.2, 5.3
		exists_f = (shell.test("-d", esc_fn) == true)
	else
		exists_f = (shell.test("-d", esc_fn) == 0)
	end
	
	return exists_f
end

---- Make Dir ------------------------------------------------------------------

function Util.MkDir(dir_path, opt)
	
	assertt(dir_path, "string", "Util.MkDir() illegal dir_path")
	
	if (opt == "path_only") then
		local _, _, path_only = dir_path:find("^(.+)/")
		assert(path_only)
		
		dir_path = path_only	
	end
	
	local esc_dir = Util.EscapePath(dir_path)
	
	-- no error if already exists, make parent directories as needed
	shell.mkdir("-p", esc_dir)
	assertf(Util.DirExists(esc_dir), "Util.MkDir(%S) failed", dir_path)
end

---- collect filenames ---------------------------------------------------------

function Util.CollectDirFilenames(path, filter)

	path = Util.NormalizePath(path)
	assertf(Util.DirExists(path), "error, dir %S doesn't exist", path)
	
	path = Util.EscapePath(path)
	
	local file_t
	
	if (filter) then
		file_t = tshell.find(path, '-iname "'..filter..'"', '-type f', '-printf "%p\\n"')
	else
		file_t = tshell.find(path, '-type f', '-printf "%p\\n"')
	end
	
	return file_t
end


---- Parse Time date/time string -----------------------------------------------

function Util.ParseTime(time_s)

	-- parse from RFC 822 date/time string
	local time_t, bad_char_ind = posix.strptime(time_s, "%a, %d %b %Y %T %Z")
	assertf(type(time_t) == "table", "posix.strptime() failed")
	
	-- duplicate 'day' field where expected
	time_t.day = time_t.monthday
	-- get time as integer
	local t_val = os.time(time_t)
	-- get timezone
	local tz_d = os.date("%z", t_val)
	-- decode
	local tz_hours = tonumber(tz_d) / 100
	
	-- adjust for timezome
	t_val = t_val + (tz_hours * 60 * 60)
	
	return t_val
end

---- Load File -----------------------------------------------------------------

function Util.LoadFile(fn)
	
	printf("Util.LoadFile(%S)", tostring(fn))
	assertf(type(fn) == "string", "illegal fn in Util.LoadFile()")
	
	-- resolve any env vars
	fn = Util.NormalizePath(fn)
	
	local f = io.open(fn, "r")
	assertf(f, "couldn't read-open %S", fn)
	
	local f_s = f:read("*a")
	
	f:close()
	
	printf("  read %d chars", #f_s)
	
	return f_s
end

---- Load File Lines -----------------------------------------------------------

function Util.LoadFileLines(fn)
	
	printf("Util.LoadFileLines(%S)", tostring(fn))
	assertf(type(fn) == "string", "illegal fn in Util.LoadFileLines()")
	
	-- resolve any env vars
	fn = Util.NormalizePath(fn)
	
	local f = io.open(fn, "r")
	assertf(f, "couldn't read-open %S", fn)
	
	local f_t = {}
	
	for ln in f:lines() do
		table.insert(f_t, ln)
	end
	
	f:close()
	
	printf("  read %d lines", #f_t)
	
	return f_t
end

---- Write File ----------------------------------------------------------------

function Util.WriteFile(fn, f_s)
	
	printf("Util.WriteFile(%S)", tostring(fn))
	assertf(type(fn) == "string", "illegal fn in Debian.WriteFile()")
	assertf(type(f_s) == "string", "illegal fn in Debian.WriteFile()")
	
	-- resolve any env vars
	fn = Util.NormalizePath(fn)
	
	local f = io.open(fn, "w+")
	assertf(f, "couldn't write-open %S", fn)
	
	f:write(f_s)
	f:close()
	
	printf("   wrote %d chars", #f_s)
end

--[[
--- Set File Modification Time
function SetFileModTime(fpath, mod_time, access_time)

	local res, err_s = posix.utime(fpath, mod_time, access_time)
	-- returns zero on success, nil on error (dicey)
	assertf(res, "posix.utime(%S) error %S", fpath, err_s)
end
]]
