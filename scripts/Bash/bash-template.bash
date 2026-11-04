#!/bin/bash
set -euo pipefail

yesno="${1:-"$(read -n 1 -p "Do you want to [Yn]: " yesno && echo $yesno)"}"

if [[ -z $yesno || "$yesno" =~ ^[yY]$ ]]; then
	echo entered
fi

echo -e "\e[1;32mwazaaa"

