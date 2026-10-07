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
	list_m_p="list-managed-policies.txt" > $list_m_p
	concise_list_m_p="concise-list-managed-policies.txt" > $concise_list_m_p
	blackList="blackList.txt" > $blackList
	passList="passList.txt" > $passList
	output_dir="shortend_managed_policies_folder"
	mkdir $output_dir 2>/dev/null || true
	rm -rf $output_dir/*
	TOTAL_NUMBER_OF_AWS_ACTIONS=$(counter=0 && for file in actions/*; do counter=$(($counter+$(cat $file | wc -l))); done && echo $counter)

	# TODO evidently and iotevents appear a couple time and slow down the scoring process.. if we add theses sources to this temp file and grep the source, it should be faster.
	# temp_actions_blacklist="temp_actions_blacklist.txt" > $temp_actions_blacklist

	cat_action_errors="cat-action-errors.txt" > $cat_action_errors
	grep_action_errors="grep-action-errors.txt" > $grep_action_errors


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
			local nbr_of_allowed=0
			while read -r shortPerm; do
				while read -r logPerm; do
					if [[ $logPerm == $shortPerm ]]; then
						# --- Handles the coverage ---
						# printf "\e[32m $filename\e[0m explicit pass"
						echo "$filename|$logPerm" >> $localPassList
					fi
				done < "$logFile"
				# --- Handles the overflow ---
				shortPermSource="$(echo $shortPerm | cut -d'|' -f1 | cut -d':' -f1 | tr '[:upper:]' '[:lower:]')"
				if [ "$shortPermSource" == "*" ]; then
					echo star reached TODO handles this if allow or not allow Action NotAction etc
					nbr_of_allowed=$TOTAL_NUMBER_OF_AWS_ACTIONS
				else
					shortPermAction="$(echo $shortPerm | cut -d'|' -f1 | cut -d':' -f2)"
					nbr_of_appearences=$(cat "actions/$shortPermSource.txt" 2>>"$cat_action_errors" | grep -E ^$shortPermAction 2>>"$grep_action_errors" | wc -l) && true
					nbr_of_allowed=$(($nbr_of_allowed+$nbr_of_appearences))
				fi
			done < "$outFile"
		fi
		sort -u $localPassList -o $localPassList
		nbr_of_covered_permissions=$(cat $localPassList | wc -l)
		
		coverageString="$nbr_of_covered_permissions/$nbr_of_log_permissions"
		coverageFloat=$(awk -v x1="$nbr_of_covered_permissions" -v x2="$nbr_of_log_permissions" 'BEGIN { printf "%.5f", x1 / x2 * 100 }')
		overflowLevelString="$nbr_of_allowed/$TOTAL_NUMBER_OF_AWS_ACTIONS"
		overflowLevelFloat=$(awk -v y1="$nbr_of_allowed" -v y2="$TOTAL_NUMBER_OF_AWS_ACTIONS" 'BEGIN { printf "%.5f", y1 / y2 * 100}')
		if [[ "$nbr_of_allowed" =~ "$TOTAL_NUMBER_OF_AWS_ACTIONS" ]]; then
			SCORE=0.00000
		else
			SCORE=$(awk -v z1="$coverageFloat" -v z2="$overflowLevelFloat" 'BEGIN { printf "%.5f", z1 * z2}')
		fi	
		if [[ "$SCORE" =~ ^0\.0*$ ]]; then
			score_color="\e[31m"
		else
			score_color="\e[32m"
		fi

		# Human readable list (for show)
		echo -e "$filename\n\tcoverage       : [$coverageString] => $coverageFloat %\n\toverflow level : [$overflowLevelString] => $overflowLevelFloat %\n\t\tSCORE => $score_color$SCORE\e[0m" >> "$list_m_p"
		# Machine readable list (for analysis)
		echo "$SCORE $filename" >> "$concise_list_m_p"
		
		# cat $localPassList >> $passList
		rm $localPassList
	}

	m_p_dir=${2:-$(read -p "Enter the managed policies folder directory: " -e m_p_dir && echo $m_p_dir)}

	i=0
	counter=0
	nbr_of_managed_policies=$(ls -1 $m_p_dir | grep -E ".*.json" | wc -l)
	if [ $nbr_of_managed_policies -lt 100 ]; then
		ratio=1
		add_counter=$((100/$nbr_of_managed_policies))
	else
		ratio=$(($nbr_of_managed_policies/100))
		add_counter=1
	fi
	for m_p_file in $(ls $m_p_dir); do
		if [ ! -z $(echo $m_p_file | grep -E .json$) ]; then
			analyse "$m_p_dir/$m_p_file"
		fi
		if [ $(($i % ratio)) -eq 0 ]; then
			printf "\r[$counter]" && printf "%s" "%"
			counter=$(($counter + $add_counter))
		fi
		i=$(($i+1))
	done

	sort -u $blackList -o $blackList
	sort -u $cat_action_errors -o $cat_action_errors
	sort -u $grep_action_errors -o $grep_action_errors
	sort -un $concise_list_m_p -o $concise_list_m_p

	echo -e "\nThere were $(cat $blackList | wc -l) managed policies removed. They were written to \e[0;36m$blackList --\e[0m"
	echo -e "There are $(cat $list_m_p | wc -l) managed policies that are compatible. The list was written to \e[0;36m$list_m_p --\e[0m"
	echo -e "\nShortend files written to $output_dir/ \e[0;36m--\e[0m"
	echo -e "\e[1;4;32m------\e[1;4m s2 Matching \e[1;4;92mdone\e[1;4;32m. ------\e[0m\n"
fi

if [ -z ${1:-} ]; then
	echo -e "\e[1;32mwazaaa"
else
	thisScriptDir=$(dirname "$0")
	"$thisScriptDir/s3-venn.bash" "y" "$output_dir"
fi

