#!/bin/bash
set -euo pipefail
# --- DESCRIPTION ---: Simple bash timer using "date". (max. 24 hours)

parseTimer () {
	IFS=':' read -r h1 m1 s1 <<< "16:00:52"
	IFS=':' read -r h2 m2 s2 <<< "16:16:32"

	hours=$(awk -v x1="$h1" -v x2="$h2" 'BEGIN { printf x2 - x1 }')
	minutes=$(awk -v x1="$m1" -v x2="$m2" 'BEGIN { printf x2 - x1 }') && if [ $minutes -lt 0 ];then hours=$(($hours-1));minutes="$((60-$m1+$m2))"; fi
	seconds=$(awk -v x1="$s1" -v x2="$s2" 'BEGIN { printf x2 - x1 }') && if [ $seconds -lt 0 ];then minutes=$(($minutes-1));seconds="$((60-$s1+$s2))"; fi

	echo $hours"h"$minutes"m"$seconds"s"
}

startTime="$(date +"%T")"
sleep 62
parseTimer $startTime

printf "\e[1;35mwazaaa\e[0m\n"

