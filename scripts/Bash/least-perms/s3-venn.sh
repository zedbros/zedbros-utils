#!/bin/bash
set -euo pipefail
# --- PARAMETERS ---: None => Manual mode | (runyesno: y, m_p_dir: str)
# --- DESCRIPTION ---: 

yesno=${1:-$(read -p "Proceed with Venn ? (Y/n): " yesno && echo $yesno)}

if [[ -z $yesno || "$yesno" =~ ^[yY]$ ]]; then
	echo -e "\e[4;33m--- s3 Venn started.. --\e[0m"

	m_p_dir=${2:-$(read -p "Enter the managed policies folder directory: " -e m_p_dir && echo $m_p_dir)}

	echo -e "\e[1;4;32m------\e[1;4m s3 Venn \e[1;4;92mdone\e[1;4;32m. ------\e[0m\n"
fi

if [ -z ${1:-} ]; then
	echo -e "\e[1;32mwazaaa"
else
	thisScriptDir=$(dirname "$0")
	sh "$thisScriptDir/s4-cleanup.sh" "y"
fi

