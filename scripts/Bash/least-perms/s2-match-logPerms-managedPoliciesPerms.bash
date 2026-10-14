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
	list_scores_m_p="list-scores-managed-policies.txt" > $list_scores_m_p
	blackList="blackList.txt" > $blackList
	passList="passList.txt" > $passList
	output_dir="shortend_managed_policies_folder"
	mkdir $output_dir 2>/dev/null || true
	rm -rf $output_dir/*
	TOTAL_NUMBER_OF_AWS_ACTIONS=$(counter=0 && for file in actions/*; do counter=$(($counter+$(cat $file | wc -l))); done && echo $counter)

	# TODO evidently and iotevents appear a couple time and slow down the scoring process.. if we add theses sources to this temp file and grep the source, it should be faster.
	# temp_actions_blacklist="temp_actions_blacklist.txt" > $temp_actions_blacklist

	errors_cat_action="errors-cat-action.txt" > $errors_cat_action
	errors_grep_action="errors-grep-action.txt" > $errors_grep_action


	temp_codes="temp_codes.txt"
	echo "DAR Deny Action Resource
DANR Deny Action NotResource
DNAR Deny NotAction Resource
DNANR Deny NotAction NotResource
ANAR Allow NotAction Resource
ANANR Allow NotAction NotResource
AANR Allow Action NotResource
AAR Allow Action Resource" > $temp_codes

	
	reader () {
		local workflow_code="$1"
		
		temp_sources="temp_sources.txt" > $temp_sources

		case $workflow_code in
			"DAR")
				wildcard_appears="$(grep "^\*" $outFile || true)"
				if [ -z "$wildcard_appears" ];then
					while read -r logPerm; do
						while read -r shortPerm; do
							if [[ $logPerm == $shortPerm ]]; then
								echo $filename >> $blackList
								continue_bool="1"
								return
							fi
						done < $outFile
					done < $logFile
				else
					while read -r logPerm; do
						# TODO might be able to do a pre-sort wher we go over only the shortPerm | grep firstCharacter => shorter list than the entire file.
						# like while read -r $(grep -... ...); do
						# already a start in DNAR.
						# Don't forget *|* possibilities.
						# Making a temp file to add the sources that aren't in the outFile => avoid repetition if logFile only contains ssm and there is no ssm in the outFile for example.
						logPermSource="$(echo $logPerm | cut -d'|' -f1)"
						local appears="$(grep -wo $logPermSource $temp_sources || true)"
						if [ -z "$appears" ]; then
							echo $logPermSource >> $temp_sources
							while read -r shortPerm; do
								if [[ $logPerm == $shortPerm ]]; then
									echo $filename >> $blackList
									continue_bool="1"
									return
								fi
							done < $outFile
						fi
					done < $logFile
				fi
				;;
			"DANR")
				wildcard_appears="$(grep "^\*" $outFile || true)"
				if [ -z "$wildcard_appears" ];then
					while read -r logPerm; do
						while read -r shortPerm; do
							if [[ ! $logPerm == $shortPerm ]]; then
								echo $filename >> $blackList
								continue_bool="1"
								return
							fi
						done < $outFile
					done < $logFile
				else
					while read -r logPerm; do
						logPermSource="$(echo $logPerm | cut -d'|' -f1)"
						local appears="$(grep -wo $logPermSource $temp_sources || true)"
						if [ -z "$appears" ]; then
							echo $logPermSource >> $temp_sources
							while read -r shortPerm; do
								if [[ ! $logPerm == $shortPerm ]]; then
									echo $filename >> $blackList
									continue_bool="1"
									return
								fi
							done < $outFile
						fi
					done < $logFile
				fi
				;;

			"DNAR")
				while read -r logPerm; do
					cutLogPerm="$(echo $logPerm | cut -d'|' -f1)"
					local appears="$(grep -wo $cutLogPerm $outFile || true)"
					if [ -z "$appears" ]; then
						echo $filename >> $blackList
						continue_bool="1"
						return
					else
						while read -r shortPerm; do
							if [[ ! $logPerm == $shortPerm ]]; then
								echo $filename >> $blackList
								continue_bool="1"
								return
							fi
						done < $outFile
					fi
				done < $logFile
				;;
			"DNANR")
				while read -r logPerm; do
					cutLogPerm="$(echo $logPerm | cut -d'|' -f1)"
					local appears="$(grep -wo $cutLogPerm $outFile || true)"
					if [ -z "$appears" ]; then
						echo $filename >> $blackList
						continue_bool="1"
						return
					else
						while read -r shortPerm; do
							if [[ $logPerm == $shortPerm ]]; then
								echo $filename >> $blackList
								continue_bool="1"
								return
							fi
						done < $outFile
					fi
				done < $logFile
				;;

			"ANAR")
				while read -r logPerm; do
					cutLogPerm="$(echo $logPerm | cut -d'|' -f1)"
					local appears="$(grep -wo $cutLogPerm $outFile || true)"
					if [ -z "$appears" ]; then
						echo "$filename|$logPerm" >> $localPassList
					else
						while read -r shortPerm; do
							if [[ ! $logPerm == $shortPerm ]]; then
								echo "$filename|$logPerm" >> $localPassList
							fi
						done < $outFile
					fi
				done < $logFile
				;;
			"ANANR")
				while read -r logPerm; do
					cutLogPerm="$(echo $logPerm | cut -d'|' -f1)"
					local appears="$(grep -wo $cutLogPerm $outFile || true)"
					if [ -z "$appears" ]; then
						echo "$filename|$logPerm" >> $localPassList
					else
						while read -r shortPerm; do
							if [[ $logPerm == $shortPerm ]]; then
								echo "$filename|$logPerm" >> $localPassList
							fi
						done < $outFile
					fi
				done < $logFile
				;;

			"AAR")
				local nbr_of_allowed=0
				while read -r shortPerm; do
					while read -r logPerm; do
						if [[ $logPerm == $shortPerm ]]; then
							# --- Handles the coverage ---
							echo "$filename|$logPerm" >> $localPassList
						fi
					done < $logFile
					# --- Handles the overflow ---
					shortPermSource="$(echo $shortPerm | cut -d'|' -f1 | cut -d':' -f1 | tr '[:upper:]' '[:lower:]')"
					if [ "$shortPermSource" == "*" ]; then
						printf "\nStar (*) reached\n"
						nbr_of_allowed=$TOTAL_NUMBER_OF_AWS_ACTIONS
					else
						shortPermAction="$(echo $shortPerm | cut -d'|' -f1 | cut -d':' -f2)"
						nbr_of_appearences=$(cat "actions/$shortPermSource.txt" 2>>"$errors_cat_action" | grep -E ^$shortPermAction 2>>"$errors_grep_action" | wc -l) && true
						nbr_of_allowed=$(($nbr_of_allowed+$nbr_of_appearences))
					fi 
				done < $outFile

				sort -u $localPassList -o $localPassList
				nbr_of_covered_permissions=$(cat $localPassList | wc -l)
				
				coverageString="$nbr_of_covered_permissions/$nbr_of_log_permissions"
				coverageFloat=$(awk -v x1="$nbr_of_covered_permissions" -v x2="$nbr_of_log_permissions" 'BEGIN { printf "%.5f", x1 / x2 * 100 }')
				overflowLevelString="$nbr_of_allowed/$TOTAL_NUMBER_OF_AWS_ACTIONS"
				overflowLevelFloat=$(awk -v y1="$nbr_of_allowed" -v y2="$TOTAL_NUMBER_OF_AWS_ACTIONS" 'BEGIN { printf "%.5f", y1 / y2 * 100}')
				if [[ "$nbr_of_allowed" =~ "$TOTAL_NUMBER_OF_AWS_ACTIONS" ]]; then
					SCORE="0.00000"
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
				echo "$SCORE $filename" >> "$list_scores_m_p"
				
				# cat $localPassList >> $passList
				rm $localPassList
				;;
			"AANR")
				echo hi >/dev/null
				;;
			*)
				printf "\n\e[31mWrong workflow code given.\e[0m\n"
				exit 1
				;;
		esac
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
		# Goes through explicit denials first and if nothing is denied.. moves on to the permissions
		# covered by the currently analysing managed policiy.
		local filedir=$1
		local filename=$(echo $filedir | awk -F/ '{print $NF}' | cut -d'.' -f1) # gets the m p name without .json
		outFile="$output_dir/shortend_$filename.txt"
		localPassList="localPassList.txt" > $localPassList


		while read -r line; do
			if [ ! -z "$continue_bool" ]; then return; fi
			main_call $line
		done < "$temp_codes"
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
	sort -u $errors_grep_action -o $errors_grep_action
	sort -n $list_scores_m_p -o $list_scores_m_p
	# --- Remove temporary files
	rm -f $temp_sources
	rm -f $temp_codes

	# --- Info print
	echo -e "\nThere were $(cat $blackList | wc -l) managed policies removed. They were written to \e[0;36m$blackList --\e[0m"
	echo -e "There are $(cat $list_scores_m_p | wc -l) managed policies that are compatible. The list was written to \e[0;36m$list_m_p --\e[0m"

	echo -e "\e[1;4;32m------\e[1;4m s2 Matching \e[1;4;92mdone\e[1;4;32m. ------\e[0m\n"
fi

if [ -z ${1:-} ]; then
	echo -e "\e[1;32mwazaaa"
else
	thisScriptDir=$(dirname "$0")
	"$thisScriptDir/s3-venn.bash" "y" "$output_dir"
fi

