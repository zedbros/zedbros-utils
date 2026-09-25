#!/bin/bash
set -euo pipefail

yesno=${1:-$(read -p $'\e[4;35mYou have launched the automatic permission fitting.\n\n\e[0mYou will be prompted:\n\t- logs folder name\n\t- starting time and date for processing\n\t- if you want to first shorten the managed policies files to just permissions\n\t- The directory of the managed policies (recommended "aws-managed-policy-tracker/policies")\n\nProceed ? (Y/n): ' yesno && echo $yesno)}

if [[ -z $yesno || "$yesno" =~ ^[yY]$ ]]; then
	if [ "${1:-}" == "y" ]; then
		echo entered auto
		logs_folder=${2:-}
		cutoff=${3:-}
		optional_s3_step=${4:-}
		m_p_dir=${5:-}
	else
		read -p $'\nEnter logs folder name: ' -e logs_folder
		read -p $'\nEnter from what time and date to filter (YYYY/MM/DD hh:mm:ss): ' -e -i "2000-00-00T12:00:00Z" cutoff
		read -n 1 -p $'\nDo you wish to do the optional s3 step ? (usefull for large amounts of managed policies) [yn]: ' optional_s3_step
		read -p $'\n\nEnter the directory of the managed polices: ' -e m_p_dir
	fi
	thisScriptDir=$(dirname "$0")
	sh $thisScriptDir/s1-filter-time-logs.sh "y" $logs_folder $cutoff $optional_s3_step $m_p_dir
fi

echo -e "\n\e[1;4;32m------\e[1;4;92m ALL DONE. \e[1;4;32m------\e[0m"
echo -e "\e[1;4;35\tmwazaaa\e[0m"
