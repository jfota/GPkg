#
# Package installation perfix
#
INSTALLATION_PREFIX=/opt/jfota

#
# Ensure all Makefile shell commands use
# the same shell.
#
SHELL                  := /bin/bash

#
# Use a time stamp as part of package name
#
TIMESTAMP              := $(shell sh -c 'date "+%Y%m%d%H%M"')

#
# Open Source ecosystem 
#
export GITHUB_REPO     ?= git@github.com:jfota


#
# Platform defs
#
# We choose to avoid "if ... else if ... else ... endif endif"
# because maintaining the nesting match is a pain.  If  we 
# had "elif" things would have been much nicer...
#
uname_A := $(shell sh -c 'uname -a | tr "[:upper:]" "[:lower:]"')

ifneq (,$(findstring mac, $(uname_A)))
    export PACKAGE  := tar.gz
    export PLATFORM := mac
endif
ifneq (,$(findstring linux, $(uname_A)))
    ifneq (,$(findstring ubuntu, $(uname_A)))
        export PACKAGE  := deb
        export PLATFORM := ubuntu
    endif
    ifneq (,$(findstring .el, $(uname_A)))
        export PACKAGE  := rpm
        export PLATFORM := redhat
    endif
endif
ifneq (,$(findstring windows, $(platform_string)))
    export PACKAGE     := zip
    export PLATFORM    := windows
endif


#
# Hardware defs 
#
ifneq (,$(findstring x86_64, $(uname_A)))
    export HARDWARE := x86_64
endif
ifneq (,$(findstring amd64,  $(uname_A)))
    export HARDWARE := x86_64
endif
ifneq (,$(findstring i386,   $(uname_A)))
    export HARDWARE := i386
endif
ifneq (,$(findstring x86-32, $(uname_A)))
    export HARDWARE := i386
endif


#
# Gradle
#
GRADLE=$(shell sh -c 'pwd')/gradlew

