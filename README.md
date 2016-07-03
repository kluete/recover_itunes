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

It will also filter illegal POSIX filenames


## Example

Mount your iPhone on Linux via something like [libimobiledevice](http://www.libimobiledevice.org)





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

This may also be of interest to you to learn about iTunes' SQLite database.


## Requirements

* Lua 5.3 because its support for 64-bit integers lets you use SQLite indices as-is
either:
* a native lsqlite.so dynamic library, built for Lua 5.3
* the command-line sqlite3 binary
* AtomicParsely to write MP4 meta-tags

On Debian you'd do something like

```shell

apt-get install lua5.3 sqlite3 atomicparsley
```


## Build Configuration

* path to JUCE source code (e.g. ~/development/git/JUCE)  

    $(JUCE_DIR)

* to support juce::String, juce::Colour  

    \#define LX_JUCE 1

* for wxWidgets, make sure wx-config is $PATH-accessible as usual

* to support wxString, wxColour  

    \#define LX_WX 1

* to enable off-thread log generation in main.cpp

    \#define LOG_FROM_ASYNC 1


## Building with CMake


## Misc

* I started writing these for a language-teaching software called "Linguamix", which is where the "lx"-prefix came from.
* source code is formatted with 8-char tabs, not spaces. So there.
* source files inevitably end wih the comment  
    // nada mas  
  ever since I used a macro-assembler that wouldn't flush the disk cache correctly, so on crash my source files would be missing a sector's worth of data.
* swearwords usually come more naturally to me in French.
