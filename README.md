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

It will handle UTF8 characters (including accents) and also filter-out illegal POSIX filenames


## Rationale

Under iOS, iTunes keeps track meta-data in its own separate database. Audio files are devoid of meta-data, with cryptic filenames such as "-49907963407597370.m4a"


## Target Audience

This utility may be of interest to:

* Linux heads on desktop/server
* who also use iPhone/iPad
* purchase lots of music on iOS' iTunes store
* want those tracks to be usable on any platform they see fit -- with their complete meta-data
* aren't particularly fond of iTunes' desktop app under OSX/Windows
* find audio fingerprinting not fully reliable
* anyone curious about iTunes' SQLite database


## Requirements

* [Lua 5.3](http://github.com/lua) because its 64-bit integers can handle SQLite indices as-is
* the command-line sqlite3 binary
* **OR** a native lsqlite.so dynamic library built for Lua 5.3
* [AtomicParsely](https://github.com/wez/atomicparsley) to write MP4 meta-tags

On Debian you'd do something like

```bash
apt-get install lua5.3 sqlite3 atomicparsley
```


## Example

Mount your iPhone on Linux via something like [libimobiledevice](http://www.libimobiledevice.org) and get device mount root location


```bash
myiosroot=$(mount -t fuse.gvfsd-fuse | cut -d ' ' -f3)"/afc:host="$(ideviceinfo -k UniqueDeviceID)
lua5.3 recover_itunes/sqltunes.lua "$myiosroot/Purchases" "$myiosroot/iTunes_Control/iTunes" out
```


## Misc

* this program is **read-only** -- no data whatsoever is written to the iPhone
* please do shere if you know how to use LuaRocks to build a version-specic Lua lib on a system with multiple Lua versions
* to run faster, copy relevat iOS files to you HDD first
* ffmpeg/avconv don't seem to handle m4a cover art
* there's a hardcoded 31-year timestamp delta, maybe because the **Julian calendar** starts on 19-December-1969
