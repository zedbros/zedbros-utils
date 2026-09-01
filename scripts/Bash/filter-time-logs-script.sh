#!/bin/bash
set -eou pipefail

read -p "Do you wish to retrieve all the permissions in all the JSON logfiles in a folder ? (Y/n): " all_bool

output="output-time-logs.txt"
> $output

filter () {
	local filename=$1
	local cutoff=$2

	jq -r --arg cutoff "$cutoff" '
		.Records[]
		| select(.eventTime >= $cutoff)
		| "\(.eventSource|split(".")[0]):\(.eventName)"
	' "$filename" | sort -u >> "$output"
}


if [[ -z "$all_bool" || "$all_bool" == "y" || "$all_bool" == "Y" ]]; then
	filedir="${1:-}"
	cutoff="${2:-}"
	if [ -z $filedir ]; then
		read -p "Enter the filedir: " -e -i "logs/*" filedir
	fi
	if [ -z $cutoff ]; then
		read -p "Enter the cutoff (example provided): " -e -i "2026-08-27T12:40:20Z" cutoff
	fi

	for filename in $filedir; do filter $filename $cutoff; done

else
	filename="${1:-}"
	cutoff="${2:-}"
	if [ -z $filename ]; then 
		read -p "Enter the filename: " -e -i "logs.json" filename
	fi
	if [ -z $cutoff ]; then
		read -p "Enter the cutoff (example provided): " -e -i "2026-08-27T12:40:20Z" cutoff
	fi

	filter $filename $cutoff
fi

sort -u $output -o $output

echo The file was written to $output
