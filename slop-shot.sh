#!/usr/bin/env bash

declare -r SCREENSHOT_SAVE="$(date +%Y.%m.%d-%H:%M).png"
declare -r SCREENSHOT_TEMP="$(mktemp).png"

function send_to_imgur {
	response=$(curl -s\
		-H "Authorization: Client-ID c9a6efb3d7932fd" \
		-H "Expect: " \
		-F "image=@${SCREENSHOT_TEMP}" \
		https://api.imgur.com/3/image.xml) 2>/dev/null
	rm "$SCREENSHOT_TEMP"
	link=$(echo "$response" | grep -oP 'http.*(?=</link>)')
	echo "$link"
	if [[ -z $p_copy ]] ; then
		echo $link | xclip -i
	fi
}

function check_dependencies {
	for ARG in $@ ; do
		if ! which $ARG &>/dev/null ; then
			echo "Missing $ARG"
			exit 1
		fi
	done
}

function save_to_path {
	mv "$SCREENSHOT_TEMP" "$1"
}

function usage {
	echo "Usage:
Save screenshots and send them to imgur easily.
-s FILE -- save to disk
-i      -- send to imgur
-x      -- don't copy"
	exit 0
}

while getopts ":hs:ix" opt; do
	case $opt in
		h)
			usage
			;;
		s)
			p_save=true
			file_path="$OPTARG"
			;;
		i)
			p_imgur=true
			;;
		x)
			p_copy=true
			;;
	esac
done

# user must do something
if [[ -z $p_imgur ]] && [[ -z $p_save ]] ; then
	echo "Specify either -i or -s option"
	exit 1
fi

check_dependencies slop import xclip curl

# take the screenshot
coordinates="$(slop -b 2 -c 0.5,0.5,0.5,0.2 -l 2> /dev/null)"
import -window root -crop "$coordinates" -quality 100 "$SCREENSHOT_TEMP" &> /dev/null


if [[ -n $p_imgur ]] ; then
	send_to_imgur
fi

# Try to be intelligent about saving
if [[ -n $p_save ]] ; then
	if [[ -d "$file_path" ]] ; then
		echo "Saving in dir $file_path"
		file_path="$file_path/$SCREENSHOT_SAVE"
		save_to_path $file_path
	elif [[ -f "$file_path" ]] ; then
		echo "File exists, overwrite? (y/n)"
		while read -r line ; do
			if [[ $line == y ]] ; then
				save_to_path "$file_path"
				exit 0
			elif [[ $line == n ]] ; then
				exit 0
			fi
		done
	else
		save_to_path "$file_path"
	fi
fi
exit 0
