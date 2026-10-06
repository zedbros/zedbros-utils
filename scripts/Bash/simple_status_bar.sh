#!/bin/bash
i=1
nbr_of_managed_policies=1600
ratio=$(($nbr_of_managed_policies/100))
for j in {1..1600}; do
	# printf "\b${sp:i++%${#sp}:1}"
	if [ $(($i % ratio)) -eq 0 ]; then
		printf "="
	fi
	i=$(($i + 1))
done
# echo -e "\e[1;32m"wazaaa
