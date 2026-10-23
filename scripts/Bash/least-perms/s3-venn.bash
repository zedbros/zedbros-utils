#!/bin/bash
set -euo pipefail
# --- PARAMETERS ---: None => Manual mode | (runyesno: y, passLists_dir: str)
# --- DESCRIPTION ---: Finds the best combination of managed policies for the IAM Role. TODO Improve it.

yesno=${1:-$(read -n 1 -p "Proceed with Venn ? [Yn]: " yesno && echo $yesno)}

if [[ -z $yesno || "$yesno" =~ ^[yY]$ ]]; then
	echo -e "\e[4;33m------ s3 Venn started.. --\e[0m"

	passLists_dir=${2:-$(read -p "Enter the pass lists folder directory: " -e passLists_dir && echo $passLists_dir)}

	nbr_of_passes=$(cat "list-scores-managed-policies.txt" | wc -l)

	coverage="covered-permissions.txt"
	managed_policies="MANAGED-POLICIES.txt" > $managed_policies

	findBestMatch="y"
	topx=""

	while [[ -z "$findBestMatch" || "$findBestMatch" =~ [yY] ]]; do
		> "$coverage"
		printf "Managed policies.. How many to add to role (\e[35m$nbr_of_passes\e[0m compatible) ? : " && read topx
		while [[ $topx -le 0 || $topx -gt $nbr_of_passes ]]; do
			read -p "Please enter a valid number smaller or equal to $nbr_of_passes: " topx
		done
		for mp in $(cat "list-scores-managed-policies.txt" | cut -d' ' -f2 | tail -$topx); do
			cat "$passLists_dir/$mp.txt" >> "$coverage"
		done

		sort -u "$coverage" -o "$coverage"
		nbr_log_perms=$(cat "log-permissions.txt" | wc -l)
		nbr_covered_perms=$(cat "$coverage" | wc -l)
		echo -e "\n\e[36m-\e[0mUsing the top \e[32m$topx\e[0m managed policies gets you \e[32m$nbr_covered_perms\e[0m/$nbr_log_perms permissions coverage.\n" &
		wait
		read -n 1 -p $'Retry with a different number of managed policies ? [Yn]: ' findBestMatch && printf "\n\n"
	done

	grep -vf "$coverage" "log-permissions.txt" > "remaining-permissions.txt"
	echo -e "\e[36m-\e[0mThere are $(cat "remaining-permissions.txt" | wc -l) permissions remaining. The list was written to \e[0;36mremaining-permissions.txt --\e[0m"

	for mp in $(cat "list-scores-managed-policies.txt" | cut -d' ' -f2 | tail -$topx); do
		echo $mp >> "$managed_policies"
	done

	echo -e "\e[36m-\e[0mThere are $topx managed policies used for this role. The list was written to \e[0;36mMANAGED-POLICIES.txt --\e[0m"
	echo -e "\e[1;4;32m------\e[1;4m s3 Venn \e[1;4;92mdone\e[1;4;32m. ------\e[0m\n"
fi

if [ -z ${1:-} ]; then
	echo -e "\e[1;32mwazaaa"
fi

