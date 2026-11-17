#!/bin/bash
set -euo pipefail

white="\e[0m"

red="\e[31m"
green="\e[32m"
yellow="\e[33m"
purple="\e[35m"
cyan="\e[36m"

ipurple="\e[95m"
icyan="\e[96m"

yesno="${1:-"$(read -n 1 -p "Do you want to [Yn]: " yesno && echo $yesno)"}" && printf "\n"

if [[ -z $yesno || "$yesno" =~ ^[yY]$ ]]; then
	echo entered
fi

echo -e "${purple}wazaaa${white}"

