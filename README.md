# About recover iTunes

This is a small Lua-based utility to recover meta-tags from tracks you have legally purchased on the iTunes store via some iOS device.

It will:

* scan a directory of untagged M4A tracks, typically from your iPhone's /Purchases directory
* fetch their meta-data from [iTunes' SQL database][1]
* save a copy of tracks while injecting their meta-data

[1]: typically located at /iTunes_Control/iTunes/MediaLibrary.sqlitedb


## Features

Recovers each track

* title
* artist
* album
* track number
* cover art bitmap
* modification/purchase date

It will handle UTF-8 characters and also filter illegal POSIX filenames


## Motivation

I was compelled to write this code because:

* I'm a Linux head (Debian) on desktop & server
* I also use iPhone/iPad
* I buy a lot of music on iOS' iTunes store
* I want those tracks to be usable on any platform I see fit
* iTunes keeps track meta-data in its own separate database
  * without it, tracks will be devoid of meta-data
  * track filenames will be something unhelpful like "-49907963407597370.m4a"
* I hate the iTunes desktop app and can't use it on Linux anyway
* audio finderprinting is unreliable

This may also be of interest to learn about iTunes' SQLite database.


## Requirements

* [Lua 5.3](http://github.com/lua) because its support for 64-bit integers lets you use SQLite indices as-is
* the command-line sqlite3 binary
* OR a native lsqlite.so dynamic library, built for Lua 5.3
* AtomicParsely to write MP4 meta-tags

On Debian you'd do something like

```shell
apt-get install lua5.3 sqlite3 atomicparsley
```


## Example

Mount your iPhone on Linux via something like [libimobiledevice](http://www.libimobiledevice.org) and get device mount root location


```shell
myiosroot=$(mount -t fuse.gvfsd-fuse | cut -d ' ' -f3)"/afc:host="$(ideviceinfo -k UniqueDeviceID)
lua5.3 "$LXGIT/recover_itunes/sqltunes.lua" "$myiosroot/Purchases" "$myiosroot/iTunes_Control/iTunes" out
```


## Misc

* to run faster, copy relevat iOS files to you HDD first
* ffmpeg doesn't handle m4a coverart
* timestamp delta
