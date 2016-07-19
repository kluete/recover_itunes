#!/usr/bin/env lua5.3

--[[
	lua5.3 sqltunes.lua
	
	UNIX Epoch (time 0) in Julian calendar is
	19-December-1969
]]

local script_fpath = arg[0]
assert(script_fpath)
local script_dir = script_fpath:match("(.*)/[^%.]+.*") or os.getenv("PWD")
assert(script_dir)

package.path = package.path..";"..script_dir.."/?.lua;../?.lua"

require "lua_shell"

-- uses sqlite3 CLI (no need for native lua 5.3 sqlite lib)
local isql = 
{
	m_db_path = "",
	m_query = "",
	
	init = function(db_path, tag_query)
		assertt(db_path, "string")
		assertt(tag_query, "string")
		m_db_path = db_path
		m_query = tag_query
	end,
	
	get_tags = function(shortname)
	
		assertt(m_query, "string")
		assertt(shortname, "string")
		local stmt_s = m_query .. "'".. shortname .. "'"
		
		local res_s = pshell.sqlite3(m_db_path, '"'..stmt_s..'"')
		assert(res_s)
		
		local e = {fn = shortname}
		
		local key_list = {"title", "date_modified", "track_n", "album", "base_path", "artist", "album_artist", "artwork"}
		
		for v in res_s:gmatch("([^|]+)|?") do
			local key = table.remove(key_list, 1)
			e[key] = v
		end
		
		return e
	end,
}

-- UNCOMMENT to use native lua sqlite3 library instead of CLI
-- isql = require "nativesqlite"

---- Collect Untagged Tracks ---------------------------------------------------

local
function CollectUntaggedTracks(src_track_path)

	assertt(src_track_path, "string")
	
	local tracks_t = Util.CollectDirFilenames(src_track_path)
	assertt(tracks_t, "table")
	
	local fn_t = {}
	local audio_ext_set = {m4a = true, mp3 = true}
	local short_to_fpath_t = {}
	local fn_blacklist_set = {}
	
	for _, fpath in ipairs(tracks_t) do
	
		local dir, shortname, body, ext = fpath:match("(.*)/(([^.]+)%.(.+))")
		assertf(ext, "couldn't split path %S", fpath)
		
		local ign_f = fn_blacklist_set[shortname]
		
		if (audio_ext_set[ext] and not ign_f) then
			-- check no duplicate
			if (not short_to_fpath_t[shortname]) then
				assertf(not short_to_fpath_t[shortname], "duplicate shortname %S", shortname)
				short_to_fpath_t[shortname] = fpath
			else
				fn_blacklist_set[shortname] = true
			end
		end
	end
	
	-- sort & exclude blacklisted
	for shortname, fpath in pairs(short_to_fpath_t) do
		if (not fn_blacklist_set[shortname]) then
			table.insert(fn_t, fpath)
		end
	end
	
	table.sort(fn_t)
	
	Log.f("sorted %d collected files", #fn_t)
	
	return fn_t
end

---- Main ----------------------------------------------------------------------

function mytunes(itun_data_dir, src_track_path, dest_path)

	assertt(itun_data_dir, "string", "illegal itun_data_dir path %S", itun_data_dir)
	assertt(src_track_path, "string", "illegal src_track_path %S", src_track_path)
	assertt(dest_path, "string", "illegal dest_path %S", dest_path)
	
	Log.Init("sqltunes.log", "%H:%M:%S > ")
	Log.f("itun_data_dir = %S", itun_data_dir)
	Log.f("src_track_path = %S", src_track_path)
	Log.f("dest_path = %S", dest_path)
	
	assertf(Util.DirExists(itun_data_dir), "itun_data_dir dir %S doesn't exist", itun_data_dir)
	
	local db_path = itun_data_dir .. "/MediaLibrary.sqlitedb"
	assertt(db_path, "string")
	assertf(Util.FileExists(db_path), "itun db %S doesn't exist", db_path)
	
	local artwork_path = itun_data_dir .. "/Artwork/Originals"
	assertf(Util.DirExists(artwork_path), "itun artwork dir %S doesn't exist", artwork_path)
	
	local q_tags = [[
			SELECT title, date_modified, track_number, album, path, item_artist, album_artist, relative_path
			FROM item_extra
				INNER JOIN item			ON item.item_pid			= item_extra.item_pid
				INNER JOIN album		ON album.album_pid			= item.album_pid
				INNER JOIN base_location	ON base_location.base_location_id	= item.base_location_id
				LEFT JOIN item_artist		ON item_artist.item_artist_pid		= item.item_artist_pid
				LEFT JOIN album_artist		ON album_artist.album_artist_pid	= album.album_artist_pid
				LEFT JOIN artwork_token		ON (
									(artwork_token.entity_pid		= item.item_pid)
									AND
									(artwork_token.artwork_source_type	= 400)
								   )
				LEFT JOIN artwork		ON artwork.artwork_token		= artwork_token.artwork_token
			
			WHERE location = ]]

	isql.init(db_path, q_tags)
	
	if (not Util.DirExists(dest_path)) then
		Util.MkDir(dest_path)
	end
		
	local fn_t = CollectUntaggedTracks(src_track_path)
	assertt(fn_t, "table")
	
	local fn_metatags_lut = {}
	
	for k, fpath in ipairs(fn_t) do
		
		Log.f("fetch [%4d/%4d] : %S", k, #fn_t, fpath)
		
		local dir, shortname, body, ext = fpath:match("(.*)/(([^.]+)%.(.+))")
		assertf(ext, "couldn't split path %S", fpath)
		
		local e = isql.get_tags(shortname)
		assertt(e, "table")
		
		-- delay timestamp 31 years cause is Gregorian??
		local stamp_secs = e.date_modified + (31 * 365 * 24 * 60 * 60)
		e.stamp = os.date("%Y-%m-%dT%H:%M:%S%z", stamp_secs)
		
		if (e.artwork and ("" ~= e.artwork)) then
			e.cover = artwork_path .. "/" .. e.artwork
		end
		
		Log.f("%S", shortname)
		Log.f("  title         = %S", e.title)
		Log.f("  artist        = %S", e.artist)
		Log.f("  album         = %S", e.album)
		Log.f("  date_modified = %s", tostring(e.stamp))
		Log.f("  track_n       = %s (%s)", tostring(e.track_n), type(e.track_n))
		Log.f("  cover         = %s", tostring(e.cover))
		Log.f("")
		
		-- can happen with large iTunes library where different dirs contain same filename
		assertf(not fn_metatags_lut[shortname], "duplicate (short) filename %S", shortname)
		
		fn_metatags_lut[shortname] = e
	end
	
	-- count # artists in this batch
	local artist_cnt_t = {}
	
	for shortname, e in pairs(fn_metatags_lut) do
		
		local artist = e.artist
		if (not artist_cnt_t[artist]) then
			artist_cnt_t[artist] = 1
		else
			artist_cnt_t[artist] = artist_cnt_t[artist] + 1
		end
	end
	
	-- COPY & TAG
	for k, fpath in ipairs(fn_t) do
		
		Log.f("tagging [%4d/%4d] : %S", k, #fn_t, fpath)
		
		local dir, shortname, body, ext = fpath:match("(.*)/(([^.]+)%.(.+))")
		assertf(ext, "couldn't split path %S", fpath)
		
		local e = fn_metatags_lut[shortname]
		assert(type(e) == "table")
		
		-- remove double-quotes (can't replace them?)
		e.title = e.title:gsub('"', '')
		e.album = e.album:gsub('"', '')
		
		local dest_audio_fpath
		
		if (artist_cnt_t[e.artist] > 2) and (e.album ~= "") then
			-- group by artist/album, add track#
			dest_audio_fpath = sprintf("%s/%s/%s/%02d - %s.%s", dest_path, e.artist, e.album, e.track_n, e.title, ext)
		else
			dest_audio_fpath = sprintf("%s/%s - %s.%s", dest_path, e.artist, e.title, ext)
		end
		
		Log.f("  to %S", dest_audio_fpath)
		
		local dest_track_dir = dest_audio_fpath:match("(.*)/(([^.]+)%.(.+))")
		
		if (not Util.DirExists(dest_track_dir)) then
			Util.MkDir(dest_track_dir)
		end
		
		local fpath = Util.EscapePath(fpath)
		assert(fpath)
		local dest_fpath = Util.EscapePath(dest_audio_fpath)
		
		local av_cmd = sprintf('AtomicParsley %s --output %s --preventOptimizing --tracknum %d --title %S --artist %S --album %S', fpath, dest_fpath, e.track_n, e.title, e.artist, e.album)
		
		if (e.cover and Util.FileExists(e.cover)) then
			av_cmd = av_cmd .. sprintf(' --artwork %s', e.cover)
		end
		
		-- ffmpeg doesn't handle mp4 cover art well
		-- local av_cmd = sprintf('ffmpeg -loglevel quiet -threads 1 -i %s -i %s -map_metadata 1 -c copy %s', fpath, Util.EscapePath(meta_fpath), dest_fpath)
		
		Log.ToFile(" av cmd = %s", av_cmd)
		
		os.execute(av_cmd)		-- sync (slower)
		-- io.popen(av_cmd)		-- async/pipelined is faster but screws up keyboard input / stdin
		
		pshell.touch("-d", "'"..e.stamp.."'", dest_fpath)
	end
end

---- MAIN ----------------------------------------------------------------------

local narg = #arg
assert(narg >= 2)

local src_track_path = pshell.readlink("-f", arg[1])
local itun_db_dir = pshell.readlink("-f", arg[2])

local out_path

if (arg[3]) then
	out_path = pshell.readlink("-f", arg[3])
else
	out_path = pshell.readlink("-f", "./iTunes_2016")
end

mytunes(itun_db_dir, src_track_path, out_path)

