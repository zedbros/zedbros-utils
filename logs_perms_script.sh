#!/bin/bash

echo "Enter log folder path (default: logs)"
read -p "folder_path: " folder_path

if [ $output_path == ""]; then
    folder_path="logs"
fi

echo "Enter name for the output .txt file: (default: all_permissions.txt)"
read -p "filename: " output_name

if [ $output_name == ""]; then
	output_name="all_permissions.txt"
else
	output_name="$output_name".txt
fi

#for filename in $folder_path/*; do for i in {0..$(jq '.Records | length-1' ${filename/$folder_path\//""})}; do echo  ${filename/$folder_path\//""}; done; done

for filename in logs/*; do for i in $(seq 0 $(jq '.Records | length-1' $filename)); do jq '((.Records['$i'].eventSource|split(".")[0]) + ":" + .Records['$i'].eventName)' $filename; done | sort -u; done | sort -u > $output_name

#rm $output_name
#cat temp_permissions.txt > $output_name #| sort -u > $output_name

#rm temp_permissions.txt
echo "Finished extracting all perms >> written into all_permissions.txt file !"
echo "But here is a sneak peak:"
echo
cat $output_name

