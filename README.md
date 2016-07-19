# About recover iTunes

This small Lua-based utility recovers meta-tag data from audio tracks that were legally purchased on the iTunes store via some iOS device.

It will:

* scan a directory of untagged M4A tracks, typically from the iPhone's /Purchases directory
* fetch their meta-data from iTunes' **SQL database**, located at /iTunes_Control/iTunes/MediaLibrary.sqlitedb
* save a copy of each track while injecting its meta-data


## Features

Recovers the following meta-data

* title
* artist
* album
* track number
* cover art bitmap
* modification/purchase date

Handles UTF8 characters (including accents) and filters-out illegal characters in POSIX filenames


## Rationale

Under iOS, iTunes keeps track meta-data in its own separate database. Audio files are devoid of meta-data, with cryptic filenames such as "-49907963407597370.m4a"


## Target Audience

This may be of interest to:

* Linux heads on desktop/server
* who also use iPhone/iPad
* purchase lots of music on iOS' iTunes store
* want to enjoy those tracks on any platform they see fit -- with their complete meta-data
* can't run iTunes on Linux
* find audio fingerprinting imperfect

As well as anyone curious about SQLite under iTunes.


## Requirements

* [Lua 5.3](http://github.com/lua) because its 64-bit integers can handle SQLite indices as-is
* the command-line sqlite3 binary
* **OR** a native [Lua SQLite](https://github.com/LuaDist2/lsqlite3) dynamic library built for Lua 5.3
* [AtomicParsely](https://github.com/wez/atomicparsley) to write MP4 meta-tags

On Debian you'd do something like

```bash
apt-get install lua5.3 sqlite3 atomicparsley
```


## Example

Mount your iPhone on Linux via something like [libimobiledevice](http://www.libimobiledevice.org), then:

```bash
myiosroot=$(mount -t fuse.gvfsd-fuse | cut -d ' ' -f3)"/afc:host="$(ideviceinfo -k UniqueDeviceID)
lua5.3 recover_itunes/sqltunes.lua "$myiosroot/Purchases" "$myiosroot/iTunes_Control/iTunes" out
```

## Fineprint & Cop-out

* this program is **read-only** -- no data whatsoever is written to the iPhone
* do not try to write modified files back to the iPhone manually; at best they'll be ignored by iTunes, at worst something with break
* it is *theoretically* possible to retrieve meta-data from tracks from the global iTunes library (i.e. outside the /Purchases directory) but this program isn't designed for it. In a large audio library you're likely to encounter files with the same (short) filename, in different sub-directories, which this program doesn't currently handle as tracks are indexed on their short filename.
* use at your own risk
* 


## Notes

* there's currently a hardcoded (hackish) 31-year timestamp offset for the purchase date, maybe because the **Julian calendar** starts on 19-December-1969
* it runs slower when files are read directly via FUSE's afc protocol. To speed it up, copy relevant iOS files to your HDD first, then process them locally
* please do shere if you know how to use LuaRocks to build a version-specic Lua lib on a system with multiple Lua versions
* ffmpeg/avconv don't seem to handle m4a cover art

