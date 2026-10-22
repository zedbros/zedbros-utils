#!/bin/bash
set -euo pipefail

yesno=${1:-$(read -n 1 -p $'\e[4;35mYou have launched the automatic permission fitting.\n\n\e[0mYou will be prompted:\n\t- logs folder name\n\t- starting time and date for processing\n\t- The directory of the managed policies (recommended "aws-managed-policy-tracker/policies")\n\nProceed ? [Yn]: ' yesno && echo $yesno)}

if [[ -z $yesno || "$yesno" =~ ^[yY]$ ]]; then
	startTime="$(date +"%T")"
	thisScriptDir=$(dirname "$0")

	> "stats.txt"

	if [ "${1:-}" == "y" ]; then
		logs_folder=${2:-}
		cutoff=${3:-}
		m_p_dir=${4:-}
	else
		read -p $'\nEnter logs folder name: ' -e logs_folder
		read -p $'\nEnter from what time and date to filter (YYYY/MM/DD hh:mm:ss): ' -e -i "2000-00-00T12:00:00Z" cutoff
		read -p $'\nEnter the directory of the managed polices: ' -e m_p_dir
	fi

	"$thisScriptDir/s1-extract-log-permissions.bash" y $logs_folder $cutoff $m_p_dir | tee "terminal-history.txt"
	"$thisScriptDir/s4-cleanup.bash" "y" "$startTime" | tee -a "terminal-history.txt"
fi

if [ "${5:-}" == "sleep" ];then
	echo sleeping in 6..
	sleep 6
	systemctl suspend
fi

printf "\n\t\e[1;4;35mwazaaa\e[0m\n\n"

