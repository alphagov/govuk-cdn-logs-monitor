#!/bin/sh

read file

# -F handles log rotations
# -c +0 outputs the entire file (not just last ten lines)
tail -F -c +0 $file | awk '{if ($12=="404") print $11}'

# pipe output from awk and compare with the known good file of urls
# if it matches: alert
