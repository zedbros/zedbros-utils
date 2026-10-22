#!/bin/bash
set -euo pipefail
# --- PARAMETERS ---: None => Manual mode | (runyesno: y, m_p_dir: str)
# --- DESCRIPTION ---: Gets the list of the amount of permissions are covered by each
# managed policies.

yesno=${1:-$(read -p "Do you want to parse the managed policies ? (Y/n): " yesno && echo $yesno)}

if [[ -z "$yesno" || "$yesno" =~ ^[yY]$ ]]; then
	echo -e "\e[4;33m------ s2 Matching started.. --\e[0m"

	logFile="log-permissions.txt"
	nbr_of_log_permissions=$(cat $logFile | wc -l)
	list_m_p="list-managed-policies.txt" > $list_m_p
	list_scores_m_p="list-scores-managed-policies.txt" > $list_scores_m_p
	blackList="blackList.txt" > $blackList
	inexistent_sources="inexistent-sources.txt" > $inexistent_sources
	mkdir "passLists" 2>/dev/null || true && rm -rf "passLists/*"
	mkdir "alreadySeenLists" 2>/dev/null || true && rm -rf "alreadySeenLists/*"
	output_dir="shortend_managed_policies_folder" && mkdir $output_dir 2>/dev/null || true && rm -rf $output_dir/*
	TOTAL_NUMBER_OF_AWS_ACTIONS=$(counter=0 && for file in actions/*; do counter=$(($counter+$(cat $file | wc -l))); done && echo $counter)

	# TODO evidently and iotevents appear a couple time and slow down the scoring process.. if we add theses sources to this temp file and grep the source, it should be faster.
	# temp_actions_blacklist="temp_actions_blacklist.txt" > $temp_actions_blacklist

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
						echo "$shortPermSourceAndAction" >> "$temp_already_seen_sources_actions"
					fi
				done < $outFile
				;;
			"AANR")
				# printf "\nEntered AANR\n"
				while read -r shortPerm; do
					local shortPermSourceAndAction="$(echo $shortPerm | cut -d'|' -f1)"
					if [ "$shortPermSourceAndAction" == "*" ]; then
						isAdmin="0"
					else
						local shortPermSource="$(echo $shortPermSourceAndAction | cut -d':' -f1)"
						local shortPermAction="$(echo $shortPermSourceAndAction | cut -d':' -f2)"

						local appears="$(grep "^$shortPermSource" "$logFile" || true)"
						if [ ! -z "$appears" ]; then
							for logPerm in $appears; do
								if [[ ! $logPerm == $shortPerm ]]; then
									# --- Handles the coverage ---
									echo "$logPerm" >> $passList
								fi
							done
						fi
						echo "$shortPermSourceAndAction" >> "$temp_already_seen_sources_actions"
					fi
				done < $outFile
				;;

			"ANAR")
				# printf "\nEntered ANAR\n"
				while read -r shortPerm; do
					local shortPermSourceAndAction="$(echo $shortPerm | cut -d'|' -f1)"
					if [ "$shortPermSourceAndAction" == "*" ]; then
						printf "\n\e[31mException reached (ANAR * wildcard).\e[0m\n"
						isNotAdmin="0"
					else
						local shortPermSource="$(echo $shortPermSourceAndAction | cut -d':' -f1)"
						local shortPermAction="$(echo $shortPermSourceAndAction | cut -d':' -f2)"

						local appears="$(grep "^$shortPermSource" "$logFile" || true)" # watch out it's on the logFile for the allow since the order of loops in inversed. => used to get the overflow_level.
						if [ -z "$appears" ]; then
							echo "$logPerm" >> $passList
							# since this permissions source is not in the managed policy, this only means that is passes. We hand over the overflow analysis to the not-already-seen-sources-actions instead of the already-seen-sources-and-actions.
							echo $shortPermSourceAndAction >> $temp_not_already_seen_sources_actions
						else
							for logPerm in $appears; do
								if [[ ! $logPerm == $shortPerm ]]; then
									# --- Handles the coverage ---
									echo "$logPerm" >> $passList
								fi
							done
							# --- Handles the overflow ---
							echo $shortPermSourceAndAction >> $temp_already_seen_sources_actions
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
						isNotAdmin="0"
					else
						local shortPermSource="$(echo $shortPermSourceAndAction | cut -d':' -f1)"
						local shortPermAction="$(echo $shortPermSourceAndAction | cut -d':' -f2)"

						local appears="$(grep "^$shortPermSource" "$logFile" || true)" # watch out it's on the logFile for the allow since the order of loops in inversed. => used to get the overflow_level.
						if [ -z "$appears" ]; then
							echo "$logPerm" >> $passList
							# since this permissions source is not in the managed policy, this only means that is passes. We hand over the overflow analysis to the not-already-seen-sources-actions instead of the already-seen-sources-and-actions.
							echo $shortPermSourceAndAction >> $temp_not_already_seen_sources_actions
						else
							for logPerm in $appears; do
								if [[ $logPerm == $shortPerm ]]; then
									# --- Handles the coverage ---
									echo "$logPerm" >> $passList
								fi
							done
							# --- Handles the overflow ---
							echo $shortPermSourceAndAction >> $temp_already_seen_sources_actions
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
		# --- IMPORTANT STEP otherwise if there are two List* for example they will erase one another in the removeWildcards function
		sort -u $temp_already_seen_sources_actions -o $temp_already_seen_sources_actions
		sort -u $temp_not_already_seen_sources_actions -o $temp_not_already_seen_sources_actions
		removeWildcards () {
			# --- This removes all the wildcard overlaps: List* removes all ListTopics, etc...
			# Generated by ClaudeAI
			awk -F: '
			{
				full[NR]   = $0
				svc[NR]    = $1
				rest[NR]   = substr($0, length($1) + 2)
				if (rest[NR] ~ /[*?[]/) is_pattern[NR] = 1
			}
			END {
				for (p = 1; p <= NR; p++) {
					regex = glob2regex(rest[p])
					for (i = 1; i <= NR; i++) {
						if (i == p || removed[i] || svc[i] != svc[p]) continue
						if (rest[i] ~ ("^" regex "$")) removed[i] = 1
					}
				}
				for (i = 1; i <= NR; i++) if (!removed[i]) print full[i]
			}
			function glob2regex(g, out, i, c) {
				out = ""
				for (i = 1; i <= length(g); i++) {
					c = substr(g, i, 1)
					if (c == "*") out = out ".*"
					else if (c == "?") out = out "."
					else if (c ~ /[].^$(){}|+[\\]/) out = out "\\" c
					else out = out c
				}
				return out
			}
			' "$1"
		}
		
		removeWildcards "$temp_already_seen_sources_actions" > "final-allow.txt"

		# --- All but the listed perms ---
		# So first we check if there are any allow not actions. If yes, we remove wildcards.
		# Then we check if any of the listed perms are in temp-final-m-p-source-actions.txt. If yes we remove it as an allow action overwrites and allow notAction.
		# The permissions remaining are those that are excluded (soft deny). There is no overlap now between allow action and notAction,
		# so we can simply calculate it's overflow level by $TOTAL_NUMBER_OF_AWS_ACTIONS - $nbr_of_not_allowed + $nbr_of_allowed.
		if [ ! -z "$temp_not_already_seen_sources_actions" ]; then
			removeWildcards "$temp_not_already_seen_sources_actions" > "temp-final-not-allow.txt"
			> "final-not-allow.txt"

			while read -r notAction; do
				if [[ -z "$(grep "$notAction" "final-allow.txt" 2>"yes.txt" || true)" ]]; then
					echo "$notAction" >> "final-not-allow.txt"
				fi
			done < "temp-final-not-allow.txt"
			# --- Parses the overflow ---
			while read -r finalNotSourceAction; do
				local uncasedNotSource="$(echo $finalNotSourceAction | cut -d':' -f1 | tr '[:upper:]' '[:lower:]')"
				local finalNotAction="$(echo $finalNotSourceAction | cut -d':' -f2)"
				while read -r notAction; do
					if [[ $notAction == $finalNotAction ]]; then nbr_of_not_allowed=$(($nbr_of_not_allowed+1)); fi
				done < "actions/$uncasedNotSource.txt"
			done < "final-not-allow.txt"
		fi
		# --- Parses the overflow ---
		while read -r finalSourceAction; do
			local uncasedSource="$(echo $finalSourceAction | cut -d':' -f1 | tr '[:upper:]' '[:lower:]')"
			local finalAction="$(echo $finalSourceAction | cut -d':' -f2)"
			while read -r action; do
				if [[ $action == $finalAction ]]; then nbr_of_allowed=$(($nbr_of_allowed+1)); fi
			done 2>/dev/null < "actions/$uncasedSource.txt" || true
		done < "final-allow.txt"
		sort -u $passList -o $passList

		if [ -z "$isAdmin" ]; then
			total_nbr_of_allowed=$nbr_of_allowed
			if [[ ! "$nbr_of_not_allowed" =~ 0 ]]; then
				total_nbr_of_allowed=$(($total_nbr_of_allowed+$TOTAL_NUMBER_OF_AWS_ACTIONS-$nbr_of_not_allowed))
			fi
		else
			nbr_of_covered_permissions=$nbr_of_log_permissions
			total_nbr_of_allowed=$TOTAL_NUMBER_OF_AWS_ACTIONS
		fi

		# for venn diagram
		cat $passList >> "passLists/$filename.txt" 

		coverageString="$nbr_of_covered_permissions/$nbr_of_log_permissions"
		coverageFloat=$(awk -v x1="$nbr_of_covered_permissions" -v x2="$nbr_of_log_permissions" 'BEGIN { printf "%.5f", x1 / x2 * 100 }')

		overflowLevelString="$total_nbr_of_allowed/$TOTAL_NUMBER_OF_AWS_ACTIONS"
		overflowLevelPercentage=$(awk -v y1="$total_nbr_of_allowed" -v y2="$TOTAL_NUMBER_OF_AWS_ACTIONS" 'BEGIN { printf "%.5f", y1 / y2 * 100}')
		# TODO check if this causes a division by zero error:
		overflowLevelFloat=$(awk -v z1="$overflowLevelPercentage" 'BEGIN { printf "%.5f", 1.00000 / z1}')

		if [[ "$total_nbr_of_allowed" =~ "$TOTAL_NUMBER_OF_AWS_ACTIONS" ]]; then
			SCORE="0.00000"
			score_color="\e[33m"
		else
			SCORE=$(awk -v z1="$coverageFloat" -v z2="$overflowLevelFloat" -v z3="$nbr_of_covered_permissions" -v z4="$total_nbr_of_allowed" 'BEGIN { printf "%.5f", z1*100 + z2 }')
			if [[ "$SCORE" =~ ^0\.0*$ ]]; then
				score_color="\e[31m"
			else
				score_color="\e[32m"
			fi
		fi
		# --- Summary list (for show)
		echo -e "$filename\n\tcoverage       : [$coverageString] => $coverageFloat %\n\toverflow level : [$overflowLevelString] => $overflowLevelPercentage %\n\t\tSCORE => $score_color$SCORE\e[0m" >> "$list_m_p"
		# --- Sorted scores list (for analysis)
		echo "$SCORE $filename | coverage: [$coverageString]=> $coverageFloat % | overflow: [$overflowLevelString]=> $overflowLevelPercentage %" >> "$list_scores_m_p"

		cat $temp_already_seen_sources_actions >> "alreadySeenLists/$filename.txt" && rm $temp_already_seen_sources_actions
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

		nbr_of_allowed=0
		nbr_of_not_allowed=0

		isAdmin=""

		temp_already_seen_sources_actions="temp-already-seen-sources-actions.txt" > $temp_already_seen_sources_actions
		temp_not_already_seen_sources_actions="temp-not-already-seen-sources-actions.txt" > $temp_not_already_seen_sources_actions

		while read -r line; do
			if [ ! -z "$continue_bool" ]; then return; fi
			# echo -e "\e[35m$filename\e[0m"
			main_call $line
			# ... don't know if wait alone without the "&" does anything
			wait
		done < "$temp_codes"
		# if reached outside of the while loop, this means that the managed policy does not contain any relevant explicit denials.
		# We also only run analyse further if there are any of the log permissions allowed by the managed policy otherwise there
		# is not much point. Checking so also avoid extra unecessary computing time.
		nbr_of_covered_permissions=$(cat $passList | wc -l)
		if [[ ! "$nbr_of_covered_permissions" =~ 0 ]]; then
			parseAllow
		fi
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
	sort -n $list_scores_m_p -o $list_scores_m_p
	# --- Remove temporary files
	rm -f $temp_codes

	# --- Info print
	echo -e "\n\e[36m-\e[0mThere were $(cat $blackList | wc -l) managed policies removed. They were written to \e[0;36m$blackList --\e[0m"
	echo -e "\e[36m-\e[0mThere are $(cat $list_scores_m_p | wc -l) managed policies that are compatible. The list was written to \e[0;36m$list_m_p --\e[0m"

	echo -e "\e[1;4;32m------\e[1;4m s2 Matching \e[1;4;92mdone\e[1;4;32m. ------\e[0m\n"
fi
if [ -z "${1:-}" ]; then
	echo -e "\e[1;32mwazaaa"
else
	thisScriptDir=$(dirname "$0")
	"$thisScriptDir/s3-venn.bash" "y" "passLists"
fi

