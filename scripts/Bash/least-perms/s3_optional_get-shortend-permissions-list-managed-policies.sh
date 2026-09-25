#!/bin/bash
set -euo pipefail
# --- PARAMETERS ---: None=>Manual mode | (runyesno: y, m_p_dir: str)
# --- DESCRIPTION ---: Optional step. Use if you have a large amount of mangaged policies.
# TODO make stats of using this versus not with 1599 managed policies.

yesno=${1:-$(read -p "Do you want to parse the managed policies ? (Y/n): " yesno && echo yesno)}

if [[ -z $yesno || "$yesno" =~ ^[yY]$ ]]; then
	echo -e "\e[4;33m--- S3 Optional shortening started.. --\e[0m"
	output_dir="shortend_managed_policies_folder"
	mkdir $output_dir 2>/dev/null || true
	rm -rf $output_dir/*

	get_shortend () {
		echo $(echo $1 | awk -F/ '{print $NF}' | cut -d'.' -f1)
	}

	parse_effect_action () {
		filedir=$1
		filename=$(get_shortend $filedir)
		# jq '
		# .Statement[] | select(.Effect == "Deny") | (.Action)
		# ' "$filename"| sort -u | tr -d '",{}[] ' > ap/ap_Deny_Action.txt
		# jq '
		# .Statement[] | select(.Effect == "Deny") | (.NotAction)
		# ' "$filename"| sort -u | tr -d '",{}[] ' > ap/ap_Deny_NotAction.txt
		jq '
			.Statement
			| if type == "array" then .[] else . end
			| select(.Effect == "Allow")
			| (.Action)' "$filedir" \
			| sort -u \
			| tr -d '",{}[] ' > "$output_dir/shortend_$filename.txt"

		sed -i -E '/^\s*$/d' "$output_dir/shortend_$filename.txt" # removes empty lines
		# jq '
		# .Statement[] | select(.Effect == "Allow") | (.NotAction)
		# ' "$filename"| sort -u | tr -d '",{}[] ' > ap/ap_Allow_NotAction.txt
	}

	m_p_dir=${2:-$(read -p "Enter the managed policies folder directory: " -e m_p_dir && echo m_p_dir)}

	i=0
	counter=0
	nbr_of_managed_policies=$(ls $m_p_dir | wc -l)
	if [ $nbr_of_managed_policies -lt 100 ]; then
		ratio=1
	else
		ratio=$(($nbr_of_managed_policies/100))
	fi
	for m_p_file in $(ls $m_p_dir); do
		if [ ! -z $(echo $m_p_file | grep -E .json$) ]; then
			parse_effect_action "$m_p_dir/$m_p_file"
		fi
		if [ $(($i % ratio)) -eq 0 ]; then
			counter=$(($counter + 1))
			printf "\r[$counter]" && printf "%s" "%"
		fi
		i=$(($i+1))
	done
	printf "\n"
	echo -e "Shortend files written to $output_dir/ \e[0;36m--\e[0m"
	echo -e "\e[1;4;32m------\e[1;4m S3 Optional shortening \e[1;4;92mdone\e[1;4;32m. ------\e[0m\n"
fi

if [ -z ${1:-} ]; then
	echo -e "\e[1;32m wazaaa"
else
	thisScriptDir=$(dirname "$0")
	sh "$thisScriptDir/s4-get-managed-policies-matches.sh" "y" "$output_dir"
fi

