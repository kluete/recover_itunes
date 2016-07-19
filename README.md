# About recover iTunes

This small Lua-based utility recovers meta-tag data from audio tracks that were legally purchased on the iTunes store. It will:

* scan a directory of untagged M4A tracks, typically from the iPhone's `/Purchases` directory, mounted via [libimobiledevice](http://www.libimobiledevice.org)
* fetch their meta-data from iTunes' [SQLite](http://www.sqlite.org) database, located at `/iTunes_Control/iTunes/MediaLibrary.sqlitedb`
* fetch any cover art from `/iTunes_Control/iTunes/Artwork/Originals/`
* save a copy of each renamed track with its embedded meta-data


## Rationale

Under iTunes keeps track meta-data in its own separate database. Audio files are devoid of meta-data, with unhelpful filenames such as "-49907963407597370.m4a"

This program recovers the following meta-data:

* title
* artist
* album
* track number
* cover art bitmap
* modification/purchase date

It handles UTF-8 characters (including accents) and filters-out illegal characters in POSIX filenames


## Target Audience

This may be of interest to:

* Linux desktop users who purchase lots of music on their iOS device's iTunes store
* want to enjoy those tracks on any platform they see fit (I use my [own music player](http://www.laufenberg.ch/lxmusic/))
* can't run iTunes on Linux or don't like it on other platforms
* find audio fingerprinting lacking

As well as anyone curious about iTunes' SQLite schema.


## Requirements

* [Lua 5.3](http://github.com/lua) because its 64-bit integers can handle SQLite indices as-is
* either
  * the command-line [sqlite3](https://packages.debian.org/jessie/sqlite3) binary
  * **OR** a native [Lua SQLite](https://github.com/LuaDist2/lsqlite3) dynamic library built for Lua 5.3
* [AtomicParsely](https://github.com/wez/atomicparsley) to write MP4 meta-tags

On Debian you'd do something like

    apt-get install lua5.3 sqlite3 atomicparsley


## Usage

    sqltunes.lua <in_tracks_dir> <in_itunes_db_dir> <out_dir>



## Example

After having mounted your iPhone on Linux via [libimobiledevice](http://www.libimobiledevice.org):

    # retrieve mount point
    myiosroot=$(mount -t fuse.gvfsd-fuse | cut -d ' ' -f3)"/afc:host="$(ideviceinfo -k UniqueDeviceID)
    # run
    lua5.3 recover_itunes/sqltunes.lua "$myiosroot/Purchases" "$myiosroot/iTunes_Control/iTunes" out


## Technical details

* this program is **read-only** -- no data whatsoever is written to the iPhone
* it is *theoretically* possible to retrieve meta-data from tracks in the global iTunes library (i.e. outside the `/Purchases` directory) but this program isn't designed for it. In a large audio library you're likely to encounter multiple tracks with the same (short) filename, in different sub-directories, which this program doesn't currently handle.
* reading files directly via FUSE's AFC protocol can be slow. To speed it up, copy relevant iOS files to your HDD first, then process them locally
* there's currently a hardcoded (hackish) 31-year timestamp offset for the purchase date, maybe because the **Julian calendar** starts on 19-December-1969
* ffmpeg/avconv don't seem to correctly handle m4a cover art


## Fineprint & Cop-out

* although a trigger-happy litigator will no doubt find *something* to sue about, there's no hacking/reverse-engineering/decrypting going on here. iTunes' database is stored in the vanilla, open-source SQLite format and retrieving a track's meta-data comes down to a single `SELECT` statement with a few sub-look-ups.
* do not try to write modified files back to the iPhone manually; at best they'll be ignored by iTunes, at worst something with break
* use at your own risk
* please share any fixes/improvement
* enjoy!

