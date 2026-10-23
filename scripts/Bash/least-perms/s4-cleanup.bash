#!/bin/bash
set -euo pipefail
# --- PARAMETERS ---: (runyesno: Y/n, startTime: str, kill_program: "killprogram", put_to_sleep_after_finishing: "sleep")
# --- DESCRIPTION ---: Moves the created files into one versioned folder results.
#					   Is to be called automatically through s0 script (because of file namings). (check "mv" function for file names)
#					   If after doing it manually your files have the same names as the automatic version, then you can call it no problem.
yesno=${1:-$(read -n 1 -p "Do you want to cleanup [Y/n]: " yesno && echo $yesno)}

# Versioner pulled from zedbros-utils
vers () {
	local out_folder=$1

	mkdir $out_folder 2> /dev/null || true
	local is_ver=$(ls -1 "$out_folder/version.txt" 2>/dev/null)
	if [ ! -z $is_ver ]; then
		current_version=$(cat "$out_folder/version.txt")
		new_version=$(($current_version + 1))

		mv "$out_folder/$current_version-latest" "$out_folder/$current_version"
	else
		current_version=0
		new_version=0
	fi

	mkdir "$out_folder/$new_version-latest"
	echo $new_version > "$out_folder/version.txt"

	echo "$out_folder/$new_version-latest"
}

parseTimer () {
	IFS=':' read -r h1 m1 s1 <<< "$1"
	IFS=':' read -r h2 m2 s2 <<< "$(date +"%T")"

	hours=$(awk -v x1="$h1" -v x2="$h2" 'BEGIN { printf x2 - x1 }')
	minutes=$(awk -v x1="$m1" -v x2="$m2" 'BEGIN { printf x2 - x1 }') && if [ $minutes -lt 0 ];then hours=$(($hours-1));minutes="$((60-$m1+$m2))"; fi
	seconds=$(awk -v x1="$s1" -v x2="$s2" 'BEGIN { printf x2 - x1 }') && if [ $seconds -lt 0 ];then minutes=$(($minutes-1));seconds="$((60-$s1+$s2))"; fi

	echo $hours"h"$minutes"m"$seconds"s"
}

if [[ -z $yesno || "$yesno" =~ ^[yY]$ ]]; then
	echo -e "\n\e[4;33m------ s4 Cleanup started.. --\e[0m"

	out_folder=$(vers "results")

mvCommand='mkdir "for-further-analysis" 2>/dev/null || true && mv log-permissions.txt blackList.txt terminal-history.txt passLists alreadySeenLists for-further-analysis 2>/dev/null || true && mv *.txt for-further-analysis $out_folder 2>/dev/null || true'
	
	echo -e "All files were moved to \e[4;36m$out_folder/\e[0m. \e[36m--\e[0m"
	echo -e "\e[1;4;32m------\e[1;4m s4 Cleanup \e[1;4;92mdone\e[1;4;32m. ------\e[0m\n"

	if [ -z "${1:-}" ]; then
		eval $mvCommand
		
		if [[ "$(read -n 1 -p $'Do you want to \e[31mkill\e[0m the program ? (removes all the files created) [yN]: ' killyesno && echo $killyesno)" == "y" ]]; then
			if [ "$(read -n 1 -p $'\nDo you want to remove the actions folder ? [yN] : ' rmActions && echo $rmActions)" == "y" ]; then mv actions $out_folder 2>/dev/null || true; fi
			rm -rf results
			echo -e "\n\n\e[1;5;91m\t PROGRAM KILLED\e[0m"
		else
			printf "\n"
		fi
	else
		startTime=$2
		timeTaken=$(parseTimer "$startTime")
		printf "\e[1;4;36m---    \e[1;4;96m$timeTaken\e[1;4;36m    ---\e[0m\n\n"

		if [[ "${3:-}" == "killprogram" || "${3:-$(read -n 1 -p $'Do you want to \e[31mkill\e[0m the program ? (removes all the files created) [yN]: ' killyesno && echo $killyesno)}" =~ y ]]; then
			eval $mvCommand
			if [ "$(read -n 1 -p $'\nDo you want to remove the actions folder ? [yN] : ' rmActions && echo $rmActions)" == "y" ]; then mv actions $out_folder 2>/dev/null || true; fi
			rm -rf results
			echo -e "\n\n\e[1;5;91m\t PROGRAM KILLED\e[0m"
		else
			eval $mvCommand
			printf "\n"
		fi

		printf "\n\e[1;4;32m------ \e[1;4;92mALL DONE.\e[1;4;32m ------\e[0m\n"
	fi
fi

if [ -z "${1:-}" ]; then
	echo -e "\n\e[35mwazaaa\e[0m"
fi

