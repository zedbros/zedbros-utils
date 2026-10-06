#!/bin/bash

# $ for bash => enables multiline \n
read -p $'Do you want to proceed?\nenter (y/N): ' res

read -n 1 -p "Only respond with one character (immediate press (no enter))? [yn]: " onechar

input_that_reads_if_empty_parameter=${2:-$(read -p "Enter input2 value since none was given: " input2 && echo $input2)}

if [[ "$res" =~ ^([yY]|oops)$ ]]; then
	echo "works"
fi

case "$onechar" in
	[yY])
		echo -e "\none yes"
		;;
	[nN])
		echo -e "\none no"
		;;
	*)
		echo -e "\none ANYTHING_ELSE"
		;;
esac

echo -e "\e[1;35mwazaaa\e[0m"
