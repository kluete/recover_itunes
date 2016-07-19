
-- linked to lsqlite3.so (NOT kepler's binder)

-- uses custom-built lsqlite3 to run w/ lua 5.3 (cause supports 64-bit integers for SQL index)

require "lua_shell"

sqlite3 = require("lsqlite3")

local db
local query = ""

local q_exists = [[
		SELECT count(*)
		FROM item_extra
		WHERE location = ]]
		
local q_test = [[
		SELECT title, item_artist
		FROM item_extra
			INNER JOIN item			ON item.item_pid			= item_extra.item_pid
			LEFT JOIN item_artist		ON item_artist.item_artist_pid		= item.item_artist_pid
		WHERE location = ]]

---- Init (native) sqlite lib --------------------------------------------------

local
function init(db_path, tag_query)

	assert(sqlite3)
	assertt(query, "string")
	
	db = sqlite3.open(db_path, 'READONLY')
	assertf(db and db:isopen(), "couldn't open sqlite db %S", db_path)
	
	query = tag_query
end

local
function fname_exists(shortname)

	local stmt = db:prepare(q_exists .. '?')
	assert(stmt)
	stmt:bind_values(shortname)
	stmt:step()
	local n = stmt:get_uvalues()
	stmt:finalize()
	return n
end

local
function get_test(shortname)

	local stmt = db:prepare(q_test .. '?')
	assert(stmt)
	stmt:bind_values(shortname)
	stmt:step()
	local title, artist = stmt:get_uvalues()
	stmt:finalize()
	if (not artist) then
		-- return nil
	end
	
	return sprintf("title = %s title; artist = %S", tostring(title), tostring(artist))
end

---- Get Tags from sqlite native lib -------------------------------------------

local
function get_tags(shortname)

	assertt(shortname, "string")
	
	Log.f("fetch %S", shortname)
	
	local n = fname_exists(shortname)
	assertf(1 == n, "illegal fname_exists(%S) = %d (expected 1)", shortname, n)
		
	--[[
	local test_s = get_test(shortname)
	if (not test_s) then
		-- return {title = shortname, date_modified = 0, track_n = 0, artist = "_NO_ARTIST", album = "nil", album_artist = "nil", base_path = "caca"}
	end
	]]
	
	local stmt = db:prepare(query .. '?')
	assert(stmt)
	stmt:bind_values(shortname)
	stmt:step()
	
	local title, date_modified, track_n, album, base_path, track_artist, album_artist, artwork = stmt:get_uvalues()
	stmt:finalize()
	
	local artist = track_artist or album_artist
	
	return {fn = shortname, title = title, artist = artist or "unknown", album = album or "", date_modified = date_modified, track_n = track_n, base_path = base_path, artwork = artwork or ""}
end
	
return
{
	init = init,
	get_tags = get_tags,
}