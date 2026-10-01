#!/bin/bash
set -euo pipefail
# --- PARAMETERS ---: None => Manual mode | (runyesno: y, m_p_dir: str)
# --- DESCRIPTION ---: Gets the list of the amount of permissions are covered by each
# managed policies.

yesno=${1:-$(read -p "Do you want to parse the managed policies ? (Y/n): " yesno && echo $yesno)}

if [[ -z $yesno || "$yesno" =~ ^[yY]$ ]]; then
	echo -e "\e[4;33m--- s2 Matching started.. --\e[0m"
	logFile="log-permissions.txt"
	nbr_of_log_permissions=$(cat $logFile | wc -l)
	list_m_p="list-managed-policies.txt"
	blackList="blackList.txt" > $blackList
	passList="passList.txt" > $passList
	output_dir="shortend_managed_policies_folder"
	mkdir $output_dir 2>/dev/null || true
	rm -rf $output_dir/*

	get_shortend () {
		echo $(echo $1 | awk -F/ '{print $NF}' | cut -d'.' -f1)
	}

	analyse () {
		# Goes through explicit denials first and if nothing is denied.. moves on to the permissions
		# covered by the currently analysing managed policiy.
		local filedir=$1
		local filename=$(get_shortend $filedir)
		local outFile="$output_dir/shortend_$filename.txt"
		localPassList="localPassList.txt" > $localPassList

		jq -r '
			.Statement
			| if type == "array" then .[] else . end
			| select(.Effect == "Deny" and .Action and .Resource)
			| (.Action | if type == "array" then .[] else . end) as $a
			| (.Resource | if type == "array" then .[] else . end) as $r
			| "\($a)|\($r)"' "$filedir" \
			| sort -u > "$outFile"
		# local contains_deny="$(grep -w "$(cat $outFile)" "results/5/log-permissions.txt")" || true
		DAappears=$(cat $outFile)
		if [ ! -z "$DAappears" ]; then
			while read -r logPerm; do
				while read -r shortPerm; do
					if [[ $logPerm == $shortPerm ]]; then
						# printf "\e[31m $filename\e[0m denies an explicit action."
						echo $filename >> $blackList
						# printf "$logPerm \e[32mmatches\e[0m $shortPerm"
						return
					fi
				done < "$outFile"
			done < "$logFile"
		fi
		jq -r '
			.Statement
			| if type == "array" then .[] else . end
			| select(.Effect == "Deny" and .NotAction and .Resource)
			| (.NotAction | if type == "array" then .[] else . end) as $a
			| (.Resource | if type == "array" then .[] else . end) as $r
			| "\($a)|\($r)"' "$filedir" \
			| sort -u > "$outFile"
		DNAappears=$(cat $outFile)
		if [ ! -z  "$DNAappears" ]; then
			while read -r logPerm; do
				cutLogPerm="$(echo $logPerm | cut -d'|' -f1)"
				local appears="$(grep -wo $cutLogPerm $outFile || true)"
				if [ -z "$appears" ]; then
					# printf "\e[31m $filename\e[0m did not appear in NotAction."
					echo $filename >> $blackList
					return
				else
					while read -r shortPerm; do
						if [[ $logPerm == $shortPerm ]]; then
							# printf "\e[32m $filename\e[0m"
							echo "$filename|$shortPerm" >> $localPassList
						else
							# printf "\e[1;91m $filename\e[0m\n The managed policy above contains Deny NotAction denial (overrides all localPassList)."
							> $localPassList
							echo $filename >> $blackList
							return
						fi
					done < "$outFile"
				fi
			done < "$logFile"
		fi
		jq -r '
			.Statement
			| if type == "array" then .[] else . end
			| select(.Effect == "Allow" and .NotAction and .Resource)
			| (.NotAction | if type == "array" then .[] else . end) as $a
			| (.Resource | if type == "array" then .[] else . end) as $r
			| "\($a)|\($r)"' "$filedir" \
			| sort -u > "$outFile"
		ANAappears=$(cat $outFile)
		if [ ! -z "$ANAappears" ]; then
			while read -r logPerm; do
				cutLogPerm="$(echo $logPerm | cut -d'|' -f1)"
				local appears="$(grep -wo $cutLogPerm $outFile || true)"
				if [ -z "$appears" ]; then
					# printf "\e[32m $filename\e[0m passes"
					echo "$filename|$logPerm" >> $localPassList
				else
					while read -r shortPerm; do
						if [[ $logPerm == $shortPerm ]]; then
							# printf "\e[1;91m $filename\e[0m\n The managed policy above contains a Allow NotAction denial (overrides all localPassList)."
							sort -u $blackList -o $blackList
							return
						else
							# printf "\e[32m $filename\e[0m passes"
							echo "$filename|$logPerm" >> $localPassList
						fi
					done < "$outFile"
				fi
			done < "$logFile"
		fi

		# If we reached this far, this means that either nothing in the current managed policy we are analysing contains an explict deny on any of our permissions. This means that we can now scan for the allowed policies and how many are covered. (this was s4's previous job, but is more efficient to do it here as the matching is applied in the same loop.)
		#
		# So here under is the allow actions and there might have potentially already been some permissions validated beforehand.
		# TODO use the shortend files to get the which permissiosn it coveres exactly. Used for the Venn diagram later on.

		jq -r '
			.Statement
			| if type == "array" then .[] else . end
			| select(.Effect == "Allow" and .Action and .Resource)
			| (.Action | if type == "array" then .[] else . end) as $a
			| (.Resource | if type == "array" then .[] else . end) as $r
			| "\($a)|\($r)"' "$filedir" \
			| sort -u > "$outFile"
		AAappears=$(cat "$outFile")
		if [ ! -z "$AAappears" ]; then
			while read -r logPerm; do
				while read -r shortPerm; do
					if [[ $logPerm == $shortPerm ]]; then
						# printf "\e[32m $filename\e[0m explicit pass"
						echo "$filename|$logPerm" >> $localPassList
					fi
				done < "$outFile"
			done < "$logFile"
		fi
		sort -u $localPassList -o $localPassList
		nbr_of_covered_permissions=$(cat $localPassList | wc -l)
		echo "$nbr_of_covered_permissions/$nbr_of_log_permissions $filename" >> "$list_m_p"
		# cat $localPassList >> $passList
		rm $localPassList
	}

	m_p_dir=${2:-$(read -p "Enter the managed policies folder directory: " -e m_p_dir && echo $m_p_dir)}

	# TODO here is the percentage error.. takes into account non .json files
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
			analyse "$m_p_dir/$m_p_file"
		fi
		if [ $(($i % ratio)) -eq 0 ]; then
			printf "\r[$counter]" && printf "%s" "%"
			counter=$(($counter + 1))
		fi
		i=$(($i+1))
	done
	sort -u $blackList -o $blackList
	sort -u $list_m_p -o $list_m_p

	echo -e "\nThere were $(cat $blackList | wc -l) managed policies removed. They were written to \e[0;36m$blackList --\e[0m"
	echo -e "There are $(cat $list_m_p | wc -l) managed policies that are compatible. The list was written to \e[0;36m$list_m_p --\e[0m"
	echo -e "\nShortend files written to $output_dir/ \e[0;36m--\e[0m"
	echo -e "\e[1;4;32m------\e[1;4m s2 Matching \e[1;4;92mdone\e[1;4;32m. ------\e[0m\n"
fi

if [ -z ${1:-} ]; then
	echo -e "\e[1;32mwazaaa"
else
	thisScriptDir=$(dirname "$0")
	sh "$thisScriptDir/s3-venn.sh" "y" "$output_dir"
fi

