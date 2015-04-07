#!/bin/bash
# Screen capture and upload utility for puush
# (C) 2014 Volvagia356
#
# Requires scrot, curl, and xclip
# zenity can be optional
#
# Usage: puush-screenshot.sh [--full|--area|--help]

# Save your API key in ~/.config/puush
APIKEY=`cat ~/.config/puush`

function show_usage {
    echo "Performs screen capture and uploads to puush"
    echo "Usage: $0 [--full|--area|--file filename|--help]"
    echo "--full    Captures entire screen"
    echo "--area    Captures window or rectangular area"
    echo "--file    Upload an arbitrary file"
    echo "--help    Shows this help"
    echo "If an argument is used, the zenity UI is disabled"
}

function zenity {
    if [ $USE_ZENITY = 0 ]; then
        return 0
    else
        env zenity "$@"
        return $?
    fi
}

which zenity > /dev/null
if [ $? != 0 ]; then
    echo "zenity not available! See --help"
fi

FILENAME=/tmp/`tr -dc A-Za-z0-9 < /dev/urandom | head -c 8`.png

if [ $# = 0 ]; then
    USE_ZENITY=1
    TYPE=`zenity --list --text="Select a screenshot type:" --column="" --column="Type" --hide-header --hide-column=1 1 "Entire desktop" 2 "Single window or rectangular region" 3 "Upload file"`
elif [ $# = 1 ]; then
    USE_ZENITY=0
    if [ $1 = "--full" ]; then
        TYPE=1
    elif [ $1 = "--area" ]; then
        TYPE=2
    elif [ $1 = "--file" ]; then
        TYPE=3
    elif [ $1 = "--help" ]; then
        show_usage
        exit
    else
        echo "Invalid argument! See --help"
        exit
    fi
else
    echo "Invalid argument! See --help"
    exit
fi

if [ $? != 0 ]; then
    exit
elif [ $TYPE = 1 ]; then
    scrot $FILENAME
elif [ $TYPE = 2 ]; then
    scrot -s $FILENAME
elif [ $TYPE = 3 ]; then
    if [ $USE_ZENITY = 1 ]; then
        FILENAME=`zenity --file-selection`
    else
        FILENAME=$2
    fi
fi

if [ $TYPE != 3 ]; then
    HTML='<img src="data:image/png;base64,'`base64 $FILENAME`'" width="200px"><p>Upload this image?'
    echo $HTML | zenity --text-info --html --filename=/dev/stdin
fi

if [ $? = 0 ]; then
    RESPONSE=`curl -s -F "k=$APIKEY" -F "z=poop" -F "f=@$FILENAME" https://puush.me/api/up`
    if [ $? != 0 ]; then
        zenity --error
    else
        ARGS=(`echo $RESPONSE | tr ',' ' '`)
        if [ ${ARGS[0]} = 0 ]; then
            echo -n ${ARGS[1]} | xclip -sel clip
            zenity --info --text="URL copied to clipboard."
        else
          zenity --error
        fi
    fi
fi
if [ $TYPE != 3 ]; then
    rm $FILENAME
fi
