#!/bin/bash
set -euo pipefail
# --- PARAMETERS ---: Takes as parameters: nothing => manual mode (interactive) | (run_automatic: y, filedir: logs/*, cutoff: 2026-08-27T12:40:20Z, optional_s3_step: [yn], m_p_dir: str)
# --- DESCRIPTION ---: Retrieves all the permissions used in a folder of AWS logs.

runyesno=${1:-}
if [ $runyesno == "y" ]; then
	echo -e "\n\t\e[1;4;97mAutomatic run\e[0m"
	yesno=""
else
	echo "There was no \"y\" input.."
	echo -e "\e[1;34m(Manual mode)\e[0m"
	read -p "Retrieve all permissions in your JSON logfiles ? (Y/n): " yesno
fi


filter () {
	local local_filename=$1

	jq -r --arg cutoff "$cutoff" '
		.Records[]
		| select(.eventTime >= $cutoff)
		| "\(.eventSource|split(".")[0]):\(.eventName)"
	' "$local_filename" | sort -u >> "$output"
}


if [[ -z $yesno || "$yesno" =~ ^[yY]$ ]]; then
	echo -e "\e[0;4;33m------ s1 Filtering started.. --\e[0m"
	output="filtered-time-logs.txt" > $output

	filedir="${2:-}"
	cutoff="${3:-}"
	if [ -z $filedir ]; then
		read -p "Enter the filedir: " -e -i "logs" filedir
	fi
	if [ -z $cutoff ]; then
		read -p "Enter the cutoff (example provided): " -e -i "2026-08-27T12:40:20Z" cutoff
	fi

	for filename in $(ls $filedir); do filter "$filedir/$filename" $cutoff; done
	
	sort -u $output -o $output
	echo -e "The file was written to \e[36m$output --\e[0m"
	echo -e "\e[1;4;32m------\e[1;4m s1 Filtering \e[1;4;92mdone\e[1;4;32m. \e[1;4;32m------\e[0m\n"

	thisScriptDir=$(dirname "$0")
	if [ "$runyesno" == "y" ]; then
		optional_s3_step="${4:-}"
		m_p_dir="${5:-}"
		$thisScriptDir/s2-specifics-pruner.sh $output $optional_s3_step $m_p_dir
	else
		echo -e "\e[1;34mwazaaa\e[0m"
	fi
fi

