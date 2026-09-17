#!/bin/bash

read -p "enter (y/N): " res

if [[ "$res" =~ ^([yY]|oops)$ ]]; then
	echo "works"
fi

echo wazaaa
