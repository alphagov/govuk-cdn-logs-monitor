#!/bin/sh

srcdirectory="${1}"
masterfile="${2}"

ruby lib/accumulate_into_master.rb "$srcdirectory" "$masterfile"
