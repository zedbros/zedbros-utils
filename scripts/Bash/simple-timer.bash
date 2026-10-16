#!/bin/bash
set -euo pipefail
# --- DESCRIPTION ---: Simple bash timer using "date". (max. 24 hours)

parseTimer () {
	IFS=':' read -r h1 m1 s1 <<< "$1"
	IFS=':' read -r h2 m2 s2 <<< "$(date +"%T")"

	echo $(((10#$h2 - 10#$h1)%24))h$(((10#$m2 - 10#$m1)%60))m$(((10#$s2 - 10#$s1)%60))s
}

startTime="$(date +"%T")"
sleep 62
parseTimer $startTime

printf "\e[1;35mwazaaa\e[0m\n"

