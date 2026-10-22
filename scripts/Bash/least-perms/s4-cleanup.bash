#!/bin/bash
set -euo pipefail
# --- PARAMETERS ---: (runyesno: Y/n, startTime: str, kill_program: "killprogram", put_to_sleep_after_finishing: "sleep")
# --- DESCRIPTION ---: Is to be called automatically through s5 script (because of file namings). (check "mv" function for file names)
#					   If after doing it manually your files have the same names as the automatic version, then you can call it no problem. 
#					   Moves the 4 created files into one versioned folder results and creates a recap text file called stats.txt
yesno=${1:-$(read -n 1 -p "Do you want to cleanup [Y/n]: " yesno && echo $yesno)}

# Versioner pulled from zedbros-utils
# 1) Creates a out_folder directory if does not yet exist, with a version.txt file inside.
# If directory already, exists, moves on.
# 2) Creates a folder indexed with and integer, based on the version.
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
	
	if [ -z "${1:-}" ]; then
		mv *.txt *Lists shortend_managed_policies_folder $out_folder 2>/dev/null || true
		echo -e "All files were moved to \e[4;36m$out_folder/\e[0m. \e[36m--\e[0m"
		echo -e "\e[1;4;32m------\e[1;4m s4 Cleanup \e[1;4;92mdone\e[1;4;32m. ------\e[0m\n"

		if [[ "$(read -n 1 -p $'Do you want to \e[31mkill\e[0m the program ? [yN]: ' killyesno && echo $killyesno)" == "y" ]]; then
			mv *.txt *Lists shortend_managed_policies_folder $out_folder 2>/dev/null || true
			if [ "$(read -n 1 -p $'\nDo you want to remove the actions folder ? [yN] : ' rmActions && echo $rmActions)" == "y" ]; then mv actions $out_folder 2>/dev/null || true; fi
			rm -rf results
			echo -e "\n\n\e[1;5;91m\t PROGRAM KILLED\e[0m"
		else
			printf "\n"
		fi

	else
		echo -e "All files were moved to \e[4;36m$out_folder/\e[0m. \e[36m--\e[0m"
		echo -e "\e[1;4;32m------\e[1;4m s4 Cleanup \e[1;4;92mdone\e[1;4;32m. ------\e[0m\n"

		startTime=$2
		timeTaken=$(parseTimer "$startTime") >> "stats.txt"
		printf "\e[1;4;36m---    \e[1;4;96m$timeTaken\e[1;4;36m    ---\e[0m\n\n"
		
		if [[ "${3:-}" == "killprogram" || "${3:-$(read -n 1 -p $'Do you want to \e[31mkill\e[0m the program ? [yN]: ' killyesno && echo $killyesno)}" =~ y ]]; then
			mv *.txt *Lists shortend_managed_policies_folder $out_folder 2>/dev/null || true
			if [ "$(read -n 1 -p $'\nDo you want to remove the actions folder ? [yN] : ' rmActions && echo $rmActions)" == "y" ]; then mv actions $out_folder 2>/dev/null || true; fi
			rm -rf results
			echo -e "\n\n\e[1;5;91m\t PROGRAM KILLED\e[0m"
		else
			printf "\n"
		fi

		printf "\n\e[1;4;32m------ \e[1;4;92mALL DONE.\e[1;4;32m ------\e[0m\n"

		mv *.txt *Lists shortend_managed_policies_folder $out_folder 2>/dev/null || true
	fi
fi

if [ -z "${1:-}" ]; then
	echo -e "\n\e[35mwazaaa\e[0m"
fi
