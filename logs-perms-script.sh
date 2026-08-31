#!/bin/bash

echo "Enter log folder path (default: logs)"
read -p "folder_path: " folder_path

if [ $folder_path == ""]; then
    folder_path="logs/*"
else
	folder_path="$folder_path"/*
fi

echo "Enter name for the output .txt file: (default: all_permissions.txt)"
read -p "filename: " output_name

if [ $output_name == ""]; then
	output_name="all_permissions.txt"
else
	output_name="$output_name".txt
fi

for filename in $folder_path; do for i in $(seq 0 $(jq '.Records | length-1' $filename)); do jq '((.Records['$i'].eventSource|split(".")[0]) + ":" + .Records['$i'].eventName)' $filename; done | sort -u; done | sort -u > $output_name

echo "Finished extracting all perms >> written into all_permissions.txt file !"
echo "But here is a sneak peak:"
echo
cat $output_name
