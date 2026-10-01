#!/bin/bash
set -euo pipefail
# --- PARAMETERS ---: Takes (run_script: y, m_p_dir: str)
# --- DESCRIPTION ---: Reads managed policy folder 
runyesno=${1:-}
if [ "$runyesno" == "y" ]; then
	yesno=""
	perm_file="filtered-time-logs.txt"
else
	read -p "Do you wish to retrieve the list of aws-managed-polices matches ? (Y/n): " yesno
	perm_file=""
fi

if [[ -z $yesno || "$yesno" =~ ^[Yy]$ ]]; then
	echo -e "\e[4;33m------ S4 Matching started.. --\e[0m"
	temp_file="temp-list-managed-policies.txt" > "$temp_file"

	if [ -z $perm_file ]; then
		read -p "Enter the log permissions file directory: " -e perm_file
	fi
	m_p_dir=${2:-$(read -p "Enter the managed policies directory: " -e m_p_dir && echo $m_p_dir)}

	nbr_of_log_perms=$(wc -l $perm_file | cut -d' ' -f1)

	analyse_policy () {
		local counter=0
		while read -r perm; do
			appears=$(grep -w $perm $1) || true
			if [ ! -z "$appears" ]; then
				counter=$((counter + 1)) # mathematics $(())
			fi
		done < "$perm_file"
		if [ $counter -ne 0 ]; then
			echo "$counter/$nbr_of_log_perms $(echo "$1" | awk -F/ '{print $NF}')" >> $temp_file
		fi
	}
	
	i=0
	counter=0
	nbr_of_managed_policies=$(ls $m_p_dir | wc -l)
	echo -e "There are $nbr_of_managed_policies managed policies in your folder. \e[0;36m--\e[0m"
	if [ $nbr_of_managed_policies -lt 100 ]; then
		ratio=1
	else
		ratio=$(($nbr_of_managed_policies/100))
	fi
	for m_p_file in $(ls $m_p_dir); do
		analyse_policy "$m_p_dir/$m_p_file"
		if [ $(($i % ratio)) -eq 0 ]; then
			counter=$(($counter + 1))
			printf "\r[$counter]" && printf "%s" "%"
		fi
		i=$(($i+1))
	done
	printf "\n"
	cat $temp_file | sort -nr > "list-managed-policies.txt"
	echo -e "There are $(cat $temp_file | wc -l) managed policies that match (contain at least 1 common permissions). \e[0;36m--\e[0m"
	rm $temp_file
	echo -e "The detailed list of managed polices was written to : \e[0;36mlist-managed-policies.txt --\e[0m"
	echo -e "\e[1;4;32m------\e[1;4m S4 Matching \e[1;4;92mdone\e[1;4;32m. ------\e[0m\n"
fi

if [ -z $runyesno ]; then
	echo -e "\e[1;32m wazaaa"
else
	thisScriptDir=$(dirname "$0")
	sh "$thisScriptDir/s5-get-permissions-coverage.sh" "y" "" $m_p_dir
fi

