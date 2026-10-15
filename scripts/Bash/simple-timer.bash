#!/bin/bash
set -euo pipefail
# Simple bash timer using "date".

parseTimer () {
	IFS=':' read -r h1 m1 s1 <<< "$1"
	IFS=':' read -r h2 m2 s2 <<< "$(date +"%T")"

	echo $((($h2-$h1)%24))h$((($m2-$m1)%60))m$((($s2-$s1)%60))s
}

startTime=$(date +"%T")
sleep 62
parseTimer $startTime

printf "\e[1;35mwazaaa\e[0m\n"

