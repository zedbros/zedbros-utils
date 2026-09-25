#!/bin/bash
set -euo pipefail
# --- PARAMETERS ---: None=>manual mode | (runyesno: y, top_x: if s4 gives "" => enter manual | int, m_p_dir: str)

yesno=${1:-$(read -p "Do you want to get the coverage of top x managed policies (Y/n): " yesno && echo $yesno)}

if [[ -z $yesno || "$yesno" =~ ^[yY]$ ]]; then
	echo -e "\e[4;33m------ S5 Coverage started.. --\e[0m"
	if [ "${1:-}" == "y" ]; then
		logPermissions="filtered-time-logs.txt"
		listManagedPolicies="list-managed-policies.txt"
		m_p_dir="$3"
	else
		read -p "Enter log permissions file directory: " -e logPermissions
		read -p "Enter fitted managed policies text file location: " -e listManagedPolicies
		read -p "Enter managed policies location (normal or shortend): " -e m_p_dir
		# TODO choose managed or shortend version instead. => just faster ?
	fi

	nbr_of_m_p=$(ls $m_p_dir | wc -l)
	nbr_of_matched_m_p=$(cat $listManagedPolicies | wc -l)

	top_x=${2:-$(read -p "Enter the top x <= $nbr_of_matched_m_p matched managed policies you want to cover: " top_x && echo $top_x)}
	while [ $top_x -gt $nbr_of_matched_m_p ]; do
		echo -e "\e[0;36m------\e[0m There are $nbr_of_matched_m_p matched managed policies in your folder. Please enter a number less or equal to this amount. \e[0;36m--\e[0m"
		read -p "Enter number: " top_x
	done

	logPerm="remaining-logged-permissions.txt"
	topX="top_$top_x.txt"
	cat $logPermissions > $logPerm
	cat $listManagedPolicies | head -"$top_x" | cut -d' ' -f2 > $topX

	analyse () {
		m_p_name="$1"
		while read -r perm; do
			if [ -z $perm ]; then
				continue
			fi
			appears=$(grep -w $perm "$m_p_dir/$m_p_name") || true
			if [ ! -z "$appears" ]; then
				sed -i -E 's/^.*'$perm'.*$//' $logPerm
			fi
		done < "$logPerm"
	}

	# echo -e "\e[33m------ \e[93m[debug]\e[33m --- Size of logPerm file $(cat $logPerm | wc -c) --\e[0m"
	while read -r m_p_name; do
		analyse $m_p_name
		# echo -e "\e[0;33m------ \e[93m[debug]\e[33m --- Size of logPerm file $(cat $logPerm | wc -c) after analysing $m_p_name --\e[0m"
	done < "$topX"

	sed -i -E '/^\s*$/d' $logPerm
	echo -e "There are $(cat $logPerm | wc -l) permissions left. \e[0;36m--\e[0m"
	echo -e "The top $top_x managed polices were written to : \e[0;36m$topX --\e[0m"
	echo -e "The remaining log permissions were written to : \e[0;36m$logPerm --\e[0m"
	echo -e "\e[1;4;32m------\e[1;4m S5 Coverage \e[1;4;92mdone\e[1;4;32m. ------\e[0m\n"
fi

if [ -z $yesno ]; then
	echo -e "\e[1;32mwazaaa"
else
	thisScriptDir=$(dirname "$0")
	sh "$thisScriptDir"/s6-cleanup.sh "y"
fi

