#!/bin/bash
set -euo pipefail
# --- PARAMETERS ---: None => manual mode (interactive) | (run_automatic: [yY], logs_dir: logs/*, cutoff: 2026-08-27T12:40:20Z, m_p_dir: str)
# --- DESCRIPTION ---: Retrieves all the permissions used in a folder of AWS logs.

runyesno=${1:-}
if [[ "$runyesno" =~ [yY] ]]; then
	echo -e "\n\t\e[1;4;97mAutomatic run\e[0m"
	yesno=""
else
	echo "There was no [yY] input.."
	echo -e "\e[1;34m(Manual mode)\e[0m"
	read -n 1 -p "Retrieve all permissions in your JSON logfiles ? [Y/n]: " yesno
	printf "\n"
fi

filter () {
	# --- Parses one log file by getting it's permissions source, eventName and resource (TODO fix the resource section).
	# --- Adds these concatenated values to a text file: "log-permissions.txt" with source:eventName|resource.
	local local_filename=$1
	jq -r --arg cutoff "$cutoff" '
		.Records[]
		| select(.eventTime >= $cutoff)
		| "\(.eventSource|split(".")[0]):\(.eventName)|\(.resources.[0].ARN)"
	' "$local_filename" | sort -u >> "$output"
}

if [[ -z $yesno || "$yesno" =~ [yY] ]]; then
	echo -e "\e[0;4;33m------ s1 Filtering started.. --\e[0m"

	output="log-permissions.txt" > $output
	logs_dir="${2:-"$(read -p "Enter the logs_dir: " -e -i "logs" logs_dir && echo $logs_dir)"}"
	cutoff="${3:-"$(read -p "Enter the cutoff (example provided): " -e -i "2026-08-27T12:40:20Z" cutoff && echo $cutoff)"}"

	for filename in $(ls $logs_dir); do filter "$logs_dir/$filename" $cutoff; done
	
	sort -u $output -o $output

	echo -e "\e[36m-\e[0mThe file was written to \e[36m$output --\e[0m"
	echo -e "\e[1;4;32m------\e[1;4m s1 Filtering \e[1;4;92mdone\e[1;4;32m. \e[1;4;32m------\e[0m\n"
fi

if [ "$runyesno" == "y" ]; then
	thisScriptDir=$(dirname "$0")
	m_p_dir="${4:-}"
	"$thisScriptDir/s2-match-logPerms-managedPoliciesPerms.bash" "y" $m_p_dir
else
	echo -e "\e[1;34mwazaaa\e[0m"
fi
