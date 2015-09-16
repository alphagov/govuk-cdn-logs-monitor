#!/bin/sh

srcdirectory="${1}"
masterfile="${2}"

ruby accumulate_into_master.rb "$srcdirectory" "$masterfile"
