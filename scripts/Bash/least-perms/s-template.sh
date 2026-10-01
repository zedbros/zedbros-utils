#!/bin/bash
set -euo pipefail
# --- PARAMETERS ---: None => Manual mode | (runyesno: y, m_p_dir: str)
# --- DESCRIPTION ---: 

yesno=${1:-$(read -p "Proceed ? (Y/n): " yesno && echo $yesno)}

if [[ -z $yesno || "$yesno" =~ ^[yY]$ ]]; then
	echo -e "\e[4;33m--- sx xxx started.. --\e[0m"

	m_p_dir=${2:-$(read -p "Enter the managed policies folder directory: " -e m_p_dir && echo $m_p_dir)}

	echo -e "\e[1;4;32m------\e[1;4m sx xxx \e[1;4;92mdone\e[1;4;32m. ------\e[0m\n"
fi

if [ -z ${1:-} ]; then
	echo -e "\e[1;32mwazaaa"
else
	thisScriptDir=$(dirname "$0")
	sh "$thisScriptDir/sx-xxx.sh" "y" "$output_dir"
fi

