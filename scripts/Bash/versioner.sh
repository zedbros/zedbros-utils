#!/bin/bash
# 1) Creates a out_folder directory if does not yet exist, with a version.txt file inside.
# If directory already, exists, moves on.
#
# 2) Creates a folder indexed with and integer, based on the version.

vers () {
	out_folder=$1
	new_version=0

	mkdir $out_folder 2> /dev/null || true
	is_ver=$(ls -1 "$out_folder/version.txt" 2> /dev/null)
	if [ ! -z $is_ver ]; then
		current_version=$(cat "$out_folder/version.txt")
		new_version=$(($current_version + 1))
	fi

	echo $new_version > "$out_folder/version.txt"
	output_dir="$out_folder/$new_version"
	mkdir $output_dir
	echo $output_dir
}

vers $1

