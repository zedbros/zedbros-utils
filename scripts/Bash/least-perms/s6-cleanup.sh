#!/bin/bash
set -euo pipefail
# --- PARAMETERS ---: None=>automatic mode
# --- DESCRIPTION ---: Is to be called automatically through s5 script (because of file namings). (check "mv" function for file names)
#					   If after doing it manually your files have the same names as the automatic version, then you can call it no problem. 
#					   Moves the 4 created files into one versioned folder results and creates a recap text file called stats.txt
yesno=${1:-$(read -p "Do you want to cleanup (Y/n): " yesno && echo $yesno)}

# Versioner pulled from zedbros-utils
# 1) Creates a out_folder directory if does not yet exist, with a version.txt file inside.
# If directory already, exists, moves on.
# 2) Creates a folder indexed with and integer, based on the version.
vers () {
	local out_folder=$1
	local new_version=0

	mkdir $out_folder 2> /dev/null || true
	local is_ver=$(ls -1 "$out_folder/version.txt" 2> /dev/null)
	if [ ! -z $is_ver ]; then
		current_version=$(cat "$out_folder/version.txt")
		new_version=$(($current_version + 1))
	fi

	echo $new_version > "$out_folder/version.txt"
	local output_dir="$out_folder/$new_version"
	mkdir $output_dir
	echo $output_dir
}

if [[ -z $yesno || "$yesno" =~ ^[yY]$ ]]; then
	echo -e "\e[4;33m------ S6 Cleanup started.. --\e[0m"
	
	out_folder=$(vers "results")
	mv filtered-time-logs.txt list-managed-policies.txt remaining-logged-permissions.txt top_*.txt shortend_managed_policies_folder $out_folder 2>/dev/null || true
	echo -e "All files were moved to \e[4;36m$out_folder/\e[0m. \e[36m--\e[0m"
	
	nbrLogPerms=$(cat $out_folder/filtered-time-logs.txt | wc -l)
	topNbr=$(cat $out_folder/top_*.txt | wc -l)
	nbrRemain=$(cat $out_folder/remaining-logged-permissions.txt | wc -l)

	echo \
	"
	There were $nbrLogPerms permissions pulled from the logs.
	The top $topNbr managed policies, cover $(($nbrLogPerms-$nbrRemain)) of those permissions.
	=> $((100*($nbrLogPerms-$nbrRemain)/$nbrLogPerms))%" > $out_folder/stats.txt

	echo -e "\e[4;36mstats.txt\e[0m was created and written into \e[36m$out_folder/\e[36m. --\e[0m"
	echo -e "\e[1;4;32m------\e[1;4m S6 Cleanup \e[1;4;92mdone\e[1;4;32m. ------\e[0m\n"

	read -s -n 1 -p $'Read stats ? [y]\n' readyesno
	if [ "$readyesno" == "y" ]; then cat $out_folder/stats.txt; fi
fi

if [ -z $yesno ]; then echo -e "\e[1;4;35\tmwazaaa\e[0m"; fi

