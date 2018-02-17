#!/bin/sh
# Run this to generate all the initial makefiles, etc.
# $Id$
mkdir -p m4
autoreconf -i -v && echo Now run ./configure and make
