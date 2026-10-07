#!/bin/bash
set -euo pipefail

# --- DESCRIPTION ---: Folder versioner: Creates a folder indexed with and integer, based on the version.
# --- PARAMETERS ---: Takes directory as parameter. Returns latest folder directory.

read -p "Do you want to (Y/n): " yesno

vers () {
	local out_folder=$1

	mkdir $out_folder 2> /dev/null || true # create new folder, skip if already exists
	local is_ver=$(ls -1 "$out_folder/version.txt" 2>/dev/null) # existance variable of version.txt
	if [ ! -z $is_ver ]; then # if version.txt exists increment
		current_version=$(cat "$out_folder/version.txt")
		new_version=$(($current_version + 1))

		mv "$out_folder/$current_version-latest" "$out_folder/$current_version"
	else # else start from 0
		current_version=0
		new_version=0
	fi

	mkdir "$out_folder/$new_version-latest" # creates new version folder
	echo $new_version > "$out_folder/version.txt" # updates version.txt

	echo "$out_folder/$new_version-latest" # returns latest dir
}

# --- EXAMPLE METHOD CALL ---
# > test.txt
#
# out_folder=$(vers "results")
# mv "test.txt" $out_folder 2>/dev/null || true

printf "\e[1;35mwazaaa\e[0m\n"

