#!/bin/bash
set -euo pipefail
# --- PARAMETERS ---: None => Manual mode | (runyesno: y, m_p_dir: str)
# --- DESCRIPTION ---: Gets the list of the amount of permissions are covered by each
# managed policies.

yesno=${1:-$(read -p "Do you want to parse the managed policies ? (Y/n): " yesno && echo $yesno)}

if [[ -z $yesno || "$yesno" =~ ^[yY]$ ]]; then
	echo -e "\e[4;33m------ s2 Matching started.. --\e[0m"

	logFile="log-permissions.txt"
	nbr_of_log_permissions=$(cat $logFile | wc -l)
	list_m_p="list-managed-policies.txt" > $list_m_p
	list_scores_m_p="list-scores-managed-policies.txt" > $list_scores_m_p
	blackList="blackList.txt" > $blackList
	mkdir "passLists" 2>/dev/null || true && rm -rf "passLists/*"
	mkdir "alreadySeenLists" 2>/dev/null || true && rm -rf "alreadySeenLists/*"
	output_dir="shortend_managed_policies_folder" && mkdir $output_dir 2>/dev/null || true && rm -rf $output_dir/*
	TOTAL_NUMBER_OF_AWS_ACTIONS=$(counter=0 && for file in actions/*; do counter=$(($counter+$(cat $file | wc -l))); done && echo $counter)

	# TODO evidently and iotevents appear a couple time and slow down the scoring process.. if we add theses sources to this temp file and grep the source, it should be faster.
	# temp_actions_blacklist="temp_actions_blacklist.txt" > $temp_actions_blacklist

	errors_cat_action="errors-cat-action.txt" > $errors_cat_action

	temp_codes="temp_codes.txt"
	echo "DAR Deny Action Resource
DANR Deny Action NotResource
DNAR Deny NotAction Resource
DNANR Deny NotAction NotResource
AAR Allow Action Resource
AANR Allow Action NotResource
ANAR Allow NotAction Resource
ANANR Allow NotAction NotResource" > $temp_codes

	
	reader () {
		local workflow_code="$1"
		
		# --- WILDCARD_APPEARS EXPLANATION --- (and the reason for two similar looking nested while loops)
		# The wildcard_appears variable is used for deciding if every permission must be gone over or not.
		# If there is a permission where it's source is * in the managed policies, this means that we have to go over every logPermission.
		# The difference with there not being a * as source, means that we can cut corners. When going over log permissions, we first get it's source, which would be something like "ssm" for example. If ssm is not in the managed policy, then we can skip it entierly => avoids looping over every single managed policy permissions.
		# Finally if ssm is the managed policy, we only retrieve the permissions which source is ssm. => this reduces the cover list greatly => more optimisation.

		# --- logPermSource + appears EXPLANATION ---
		# This is represented by the Contains perms ? section in the workflow. If used with the wildcard seperation, we would miss the sources with a *.

		case $workflow_code in
			"DAR")
				# printf "\nEntered DAR\n"
				local wildcard_appears="$(grep "^\*" $outFile || true)"
				if [ -z "$wildcard_appears" ];then
					while read -r logPerm; do
						local logPermSource="$(echo $logPerm | cut -d'|' -f1 | cut -d':' -f1)"
						local appears="$(grep "^$logPermSource" "$outFile" || true)"
						if [ ! -z "$appears" ]; then
							for shortPerm in $appears; do
								if [[ $logPerm == $shortPerm ]]; then
									echo $filename >> $blackList
									continue_bool="1"
									return
								fi
							done
						fi
					done < $logFile
				else
					while read -r logPerm; do
						while read -r shortPerm; do
							if [[ $logPerm == $shortPerm ]]; then
								echo $filename >> $blackList
								continue_bool="1"
								return
							fi
						done < $outFile
					done < $logFile
				fi
				;;
			"DANR")
				# printf "\nEntered DANR\n"
				local wildcard_appears="$(grep "^\*" $outFile || true)"
				if [ -z "$wildcard_appears" ];then
					while read -r logPerm; do
						local logPermSource="$(echo $logPerm | cut -d'|' -f1 | cut -d':' -f1)"
						local appears="$(grep "^$logPermSource" "$outFile" || true)"
						if [ ! -z "$appears" ]; then
							for shortPerm in $appears; do
								if [[ ! $logPerm == $shortPerm ]]; then
									echo $filename >> $blackList
									continue_bool="1"
									return
								fi
							done
						fi
					done < $logFile
				else
					while read -r logPerm; do
						while read -r shortPerm; do
							if [[ ! $logPerm == $shortPerm ]]; then
								echo $filename >> $blackList
								continue_bool="1"
								return
							fi
						done < $outFile
					done < $logFile
				fi
				;;

			"DNAR")
				# printf "\nEntered DNAR\n"
				local wildcard_appears="$(grep "^\*" $outFile || true)"
				if [ -z "$wildcard_appears" ];then
					while read -r logPerm; do
						local logPermSource="$(echo $logPerm | cut -d'|' -f1 | cut -d':' -f1)"
						local appears="$(grep "^$logPermSource" "$outFile" || true)"
						if [ -z "$appears" ]; then
							echo $filename >> $blackList
							continue_bool="1"
							return
						else
							for shortPerm in $appears; do
								if [[ ! $logPerm == $shortPerm ]]; then
									echo $filename >> $blackList
									continue_bool="1"
									return
								fi
							done
						fi
					done < $logFile
				else
					while read -r logPerm; do
						while read -r shortPerm; do
							if [[ ! $logPerm == $shortPerm ]]; then
								echo $filename >> $blackList
								continue_bool="1"
								return
							fi
						done < $outFile
					done < $logFile
				fi
				;;
			"DNANR")
				# printf "\nEntered DNANR\n"
				local wildcard_appears="$(grep "^\*" $outFile || true)"
				if [ -z "$wildcard_appears" ];then
					while read -r logPerm; do
						local logPermSource="$(echo $logPerm | cut -d'|' -f1 | cut -d':' -f1)"
						local appears="$(grep "^$logPermSource" "$outFile" || true)"
						if [ -z "$appears" ]; then
							echo $filename >> $blackList
							continue_bool="1"
							return
						else
							for shortPerm in $appears; do
								if [[ $logPerm == $shortPerm ]]; then
									echo $filename >> $blackList
									continue_bool="1"
									return
								fi
							done
						fi
					done < $logFile
				else
					while read -r logPerm; do
						while read -r shortPerm; do
							if [[ $logPerm == $shortPerm ]]; then
								echo $filename >> $blackList
								continue_bool="1"
								return
							fi
						done < $outFile
					done < $logFile
				fi
				;;

			"AAR")
				# printf "\nEntered AAR\n"
				while read -r shortPerm; do
					local shortPermSourceAndAction="$(echo $shortPerm | cut -d'|' -f1)"
					if [ "$shortPermSourceAndAction" == "*" ]; then
						nbr_of_allowed=$TOTAL_NUMBER_OF_AWS_ACTIONS
						isAdmin="0"
					else
						local shortPermSource="$(echo $shortPermSourceAndAction | cut -d':' -f1)"
						local shortPermAction="$(echo $shortPermSourceAndAction | cut -d':' -f2)"

						local appears="$(grep "^$shortPermSource" "$logFile" || true)" # watch out it's on the logFile for the allow since the order of loops in inversed. => used to get the overflow_level.
						if [ ! -z "$appears" ]; then
							for logPerm in $appears; do
								if [[ $logPerm == $shortPerm ]]; then
									# --- Handles the coverage ---
									echo "$logPerm" >> $passList
								fi
							done
						fi
						# --- Handles the overflow ---
						if [ -z "$(grep "$shortPermSourceAndAction" "$temp_already_seen_sources_actions")" ]; then
							local uncasedShortPermSource="$(echo $shortPermSourceAndAction | cut -d':' -f1 | tr '[:upper:]' '[:lower:]')"
							local nbr_of_appearences=$(cat "actions/$uncasedShortPermSource.txt" 2>>"$errors_cat_action" | grep -E "^$shortPermAction\$" 2>"/dev/null" | wc -l) && true
							nbr_of_allowed=$(($nbr_of_allowed+$nbr_of_appearences))
							echo "$shortPermSourceAndAction|$nbr_of_appearences" >> $temp_already_seen_sources_actions
						fi
					fi
				done < $outFile
				;;
			"AANR")
				# printf "\nEntered AANR\n"
				while read -r shortPerm; do
					local shortPermSourceAndAction="$(echo $shortPerm | cut -d'|' -f1)"
					if [ "$shortPermSourceAndAction" == "*" ]; then
						nbr_of_allowed=$TOTAL_NUMBER_OF_AWS_ACTIONS
						isAdmin="0"
					else
						local shortPermSource="$(echo $shortPermSourceAndAction | cut -d':' -f1)"
						local shortPermAction="$(echo $shortPermSourceAndAction | cut -d':' -f2)"

						local appears="$(grep "^$shortPermSource" "$logFile" || true)"
						if [ ! -z "$appears" ]; then
							for logPerm in $appears; do
								if [[ ! $logPerm == $shortPerm ]]; then
									# --- Handles the coverage ---
									echo "$filename|$logPerm" >> $notPassList
								fi
							done
						fi
						# --- Handles the overflow ---
						if [ -z "$(grep "$shortPermSourceAndAction" "$temp_already_seen_sources_actions")" ]; then
							local uncasedShortPermSource="$(echo $shortPermSourceAndAction | cut -d':' -f1 | tr '[:upper:]' '[:lower:]')"
							local nbr_of_appearences=$(cat "actions/$uncasedShortPermSource.txt" 2>>"$errors_cat_action" | grep -E ^$shortPermAction 2>"/dev/null" | wc -l) && true
							nbr_of_allowed=$(($nbr_of_allowed+$nbr_of_appearences))
							echo $shortPermSourceAndAction >> $temp_already_seen_sources_actions
						fi
					fi
				done < $outFile
				;;

			"ANAR")
				# printf "\nEntered ANAR\n"
				while read -r shortPerm; do
					local shortPermSourceAndAction="$(echo $shortPerm | cut -d'|' -f1)"
					if [ "$shortPermSourceAndAction" == "*" ]; then
						printf "\n\e[31mException reached (ANAR * wildcard).\e[0m\n"
						nbr_of_not_allowed=$TOTAL_NUMBER_OF_AWS_ACTIONS
						isNotAdmin="0"
					else
						local shortPermSource="$(echo $shortPermSourceAndAction | cut -d':' -f1)"
						local shortPermAction="$(echo $shortPermSourceAndAction | cut -d':' -f2)"

						local appears="$(grep "^$shortPermSource" "$logFile" || true)" # watch out it's on the logFile for the allow since the order of loops in inversed. => used to get the overflow_level.
						if [ -z "$appears" ]; then
							echo "$logPerm" >> $notPassList
							# since this permissions source is not in the managed policy, this only means that is passes. We hand over the overflow analysis to the else section, as we keep track of all the written perms and subtract them from the $TOTAL_NUMBER_OF_AWS_ACTIONS.
						else
							for logPerm in $appears; do
								if [[ ! $logPerm == $shortPerm ]]; then
									# --- Handles the coverage ---
									echo "$logPerm" >> $notPassList
								fi
							done
							# --- Handles the overflow ---
							if [ -z "$(grep "$shortPermSourceAndAction" "$temp_already_seen_sources_actions")" ]; then
								local uncasedShortPermSource="$(echo $shortPermSourceAndAction | cut -d':' -f1 | tr '[:upper:]' '[:lower:]')"
								local nbr_of_appearences=$(cat "actions/$uncasedShortPermSource.txt" 2>>"$errors_cat_action" | grep -E ^$shortPermAction 2>"/dev/null" | wc -l) && true
								nbr_of_not_allowed=$(($nbr_of_not_allowed+$nbr_of_appearences))
								echo $shortPermSourceAndAction >> $temp_already_seen_sources_actions
							fi
						fi
					fi
				done < $outFile
				;;
			"ANANR")
				# printf "\nEntered ANANR\n"
				while read -r shortPerm; do
					local shortPermSourceAndAction="$(echo $shortPerm | cut -d'|' -f1)"
					if [ "$shortPermSourceAndAction" == "*" ]; then
						printf "\n\e[31mException reached (ANAR * wildcard).\e[0m\n"
						nbr_of_not_allowed=$TOTAL_NUMBER_OF_AWS_ACTIONS
						isNotAdmin="0"
					else
						local shortPermSource="$(echo $shortPermSourceAndAction | cut -d':' -f1)"
						local shortPermAction="$(echo $shortPermSourceAndAction | cut -d':' -f2)"

						local appears="$(grep "^$shortPermSource" "$logFile" || true)" # watch out it's on the logFile for the allow since the order of loops in inversed. => used to get the overflow_level.
						if [ -z "$appears" ]; then
							echo "$logPerm" >> $notPassList
							# since this permissions source is not in the managed policy, this only means that is passes. We hand over the overflow analysis to the else section, as we keep track of all the written perms and subtract them from the $TOTAL_NUMBER_OF_AWS_ACTIONS.
						else
							for logPerm in $appears; do
								if [[ $logPerm == $shortPerm ]]; then
									# --- Handles the coverage ---
									echo "$logPerm" >> $notPassList
								fi
							done
							# --- Handles the overflow ---
							if [ -z "$(grep "$shortPermSourceAndAction" "$temp_already_seen_sources_actions")" ]; then
								local uncasedShortPermSource="$(echo $shortPermSourceAndAction | cut -d':' -f1 | tr '[:upper:]' '[:lower:]')"
								local nbr_of_appearences=$(cat "actions/$uncasedShortPermSource.txt" 2>>"$errors_cat_action" | grep -E ^$shortPermAction 2>"/dev/null" | wc -l) && true
								nbr_of_not_allowed=$(($nbr_of_not_allowed+$nbr_of_appearences))
								echo $shortPermSourceAndAction >> $temp_already_seen_sources_actions
							fi
						fi
					fi
				done < $outFile
				;;
			*)
				printf "\n\e[31mWrong workflow code given.\e[0m\n"
				;;
		esac
	}

	parseAllow () {
		if [ -z "$isAdmin" ];then
			sort -u $passList -o $passList
			if [[ "$nbr_of_not_allowed" =~ 0 ]]; then
				nbr_of_covered_permissions=$(cat $passList | wc -l)
				total_nbr_of_allowed=$nbr_of_allowed
			else
				nbr_of_covered_permissions=$(($nbr_of_log_permissions-$nbr_of_not_allowed+$nbr_of_allowed))
				total_nbr_of_allowed=$(($TOTAL_NUMBER_OF_AWS_ACTIONS-$nbr_of_not_allowed+$nbr_of_allowed))
			fi
		else
			nbr_of_covered_permissions=$nbr_of_log_permissions
			total_nbr_of_allowed=$TOTAL_NUMBER_OF_AWS_ACTIONS
		fi

		if [[ ! "$nbr_of_covered_permissions" =~ 0 ]]; then
			# for venn diagram
			cat $passList >> "passLists/$filename.txt" 

			coverageString="$nbr_of_covered_permissions/$nbr_of_log_permissions"
			coverageFloat=$(awk -v x1="$nbr_of_covered_permissions" -v x2="$nbr_of_log_permissions" 'BEGIN { printf "%.5f", x1 / x2 * 100 }')

			overflowLevelString="$total_nbr_of_allowed/$TOTAL_NUMBER_OF_AWS_ACTIONS"
			overflowLevelPercentage=$(awk -v y1="$total_nbr_of_allowed" -v y2="$TOTAL_NUMBER_OF_AWS_ACTIONS" 'BEGIN { printf "%.5f", y1 / y2 * 100}')
			overflowLevelFloat=$(awk -v z1="$overflowLevelPercentage" 'BEGIN { printf "%.5f", 1 / z1}')

			if [[ "$total_nbr_of_allowed" =~ "$TOTAL_NUMBER_OF_AWS_ACTIONS" ]]; then
				SCORE="0.00000"
				score_color="\e[33m"
			else
				SCORE=$(awk -v z1="$coverageFloat" -v z2="$overflowLevelFloat" 'BEGIN { printf "%.5f", z1 + z2}')
				if [[ "$SCORE" =~ ^0\.0*$ ]]; then
					score_color="\e[31m"
				else
					score_color="\e[32m"
				fi
			fi
			# --- Human readable list (for show)
			echo -e "$filename\n\tcoverage       : [$coverageString] => $coverageFloat %\n\toverflow level : [$overflowLevelString] => $overflowLevelPercentage %\n\t\tSCORE => $score_color$SCORE\e[0m" >> "$list_m_p"
			# --- Machine readable list (for analysis)
			echo "$SCORE $filename" >> "$list_scores_m_p"
		fi
		rm $passList
		rm $notPassList
		cat $temp_already_seen_sources_actions >> "alreadySeenLists/$filename.txt"
		rm $temp_already_seen_sources_actions
		rm $temp_already_seen_sources_actions_NotResource
	}

	main_call () {
		local workflow_code="$1"
		local effectType="$2"
		local actionType="$3"
		local resourceType="$4"

		jq -r '
		.Statement
		| if type == "array" then .[] else . end
		| select(.Effect == "'$effectType'" and .'$actionType' and .'$resourceType')
		| (.'$actionType' | if type == "array" then .[] else . end) as $a
		| (.'$resourceType' | if type == "array" then .[] else . end) as $r
		| "\($a)|\($r)"' "$filedir" \
		| sort -u > "$outFile"
		if [[ ! -z "$(cat $outFile)" ]]; then
			reader $workflow_code
		fi
	}

	analyse () {
		continue_bool=""
		local filedir=$1
		local filename=$(echo $filedir | awk -F/ '{print $NF}' | cut -d'.' -f1) # gets the m p name without .json
		outFile="$output_dir/shortend_$filename.txt"

		passList="passList.txt" > $passList
		notPassList="notPassList.txt" > $notPassList

		nbr_of_allowed=0
		nbr_of_not_allowed=0

		isAdmin=""

		temp_already_seen_sources_actions="temp-already-seen-sources-actions.txt" > $temp_already_seen_sources_actions
		temp_already_seen_sources_actions_NotResource="temp-already-seen-sources-actions-notresource.txt" > $temp_already_seen_sources_actions_NotResource

		echo -e "\e[95m$filename\e[0m"

		while read -r line; do
			echo we doing : $line
			if [ ! -z "$continue_bool" ]; then return; fi
			main_call $line
			# ... don't know if wait alone without the "&" does anything
			wait
		done < "$temp_codes"
		# if reached outside of the while loop, this means that the managed policy does not contain any relevant explicit denials.
		parseAllow
	}

	m_p_dir=${2:-$(read -p "Enter the managed policies folder directory: " -e m_p_dir && echo $m_p_dir)}

	# --- Percentage printer
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
	# ------ Main loop
	for m_p_file in $(ls $m_p_dir | grep -E '^.*.json$'); do
		# --- Main caller
		analyse "$m_p_dir/$m_p_file"
		# --- Percentage indentation
		if [ $(($i % ratio)) -eq 0 ]; then
			printf "\r[$counter]" && printf "%s" "%"
			counter=$(($counter + $add_counter))
		fi
		i=$(($i+1))
	done

	# ------- Final actions
	sort -u $blackList -o $blackList
	sort -u $errors_cat_action -o $errors_cat_action
	sort -n $list_scores_m_p -o $list_scores_m_p
	# --- Remove temporary files
	rm -f $temp_codes

	# --- Info print
	echo -e "\nThere were $(cat $blackList | wc -l) managed policies removed. They were written to \e[0;36m$blackList --\e[0m"
	echo -e "There are $(cat $list_scores_m_p | wc -l) managed policies that are compatible. The list was written to \e[0;36m$list_m_p --\e[0m"

	echo -e "\e[1;4;32m------\e[1;4m s2 Matching \e[1;4;92mdone\e[1;4;32m. ------\e[0m\n"
fi
if [ ! -z ${1:-} ]; then
	echo -e "\e[1;32mwazaaa" else
	thisScriptDir=$(dirname "$0")
	"$thisScriptDir/s3-venn.bash" "y" "passLists"
fi

