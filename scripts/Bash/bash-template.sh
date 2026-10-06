#!/bin/bash
set -euo pipefail

read -p "Do you want to (Y/n): " yesno

if [[ -z $yesno || "$yesno" =~ ^[yY]$ ]]; then
	echo entered
fi

echo -e "\e[1;32mwazaaa"

