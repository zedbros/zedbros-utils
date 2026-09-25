#!/bin/bash
set -euo pipefail
# --- PARAMETERS ---: None (manual mode) | (destination_to_text_file: str, optional_s3_step: y, m_p_dir: str)
# --- DESCRIPTION ---: Removes the specifics in a list of permissions.
#					   ex: lambda:AddPermission20150331v2 -> lambda:AddPermission

pruneEm () {
	sed -i -E 's/^(.*:.*)[0-9]{8}.*$/\1/' $1
	echo -e "\e[1;4;32m------\e[1;4m S2 Pruning \e[1;4;92mdone\e[1;4;32m. [1;4;32m------\e[0m\n"
}

destination=${1:-}
if [ -z $destination ]; then
	read -p "Do you wish to prune the resource specific permissions ? (ex: lambda:AddPermission20150331v2 -> lambda:AddPermission) (Y/n) : " yesno
	if [[ -z $yesno || "$yesno" =~ ^[yY]$ ]]; then
		echo -e "\e[0;4;33m------ S2 Pruning started.. --\e[0m"
		read -p "Enter location of text file to prune: " -e destination
		pruneEm $destination
		echo -e "\e[1;35mwazaaa\e[0m"
	else
		echo -e "\e[1;31m Prune cancelled. \e[0m"
	fi
else
	echo -e "\e[0;4;33m------ S2 Pruning started.. --\e[0m"
	pruneEm $destination
	thisScriptDir=$(dirname "$0")
	optional_s3_step="${2:-}"
	m_p_dir="${3:-}"
	if [ "$optional_s3_step" == "y" ]; then
		sh "$thisScriptDir/s3_optional_get-shortend-permissions-list-managed-policies.sh" "y" $m_p_dir
	else
		sh "$thisScriptDir/s4-get-managed-policies-matches.sh" "y" $m_p_dir
	fi
fi

