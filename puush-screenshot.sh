#!/bin/bash
# Screen capture and upload utility for puush
# (C) 2014 Volvagia356
#
# Requires scrot, curl, zenity, and xclip

#Insert your API key here
APIKEY=""

function zenity {
    if [ $USE_ZENITY = 0 ]; then
        return 0
    else
        env zenity "$@"
        return $?
    fi
}

FILENAME=/tmp/`tr -dc A-Za-z0-9 < /dev/urandom | head -c 8`.png

if [ $# = 0 ]; then
    USE_ZENITY=1
    TYPE=`zenity --list --text="Select a screenshot type:" --column="" --column="Type" --hide-header --hide-column=1 1 "Entire desktop" 2 "Single window or rectangular region"`
elif [ $# = 1 ]; then
    USE_ZENITY=0
    if [ $1 = "--full" ]; then
        TYPE=1
    elif [ $1 = "--area" ]; then
        TYPE=2
    else
        echo "Invalid argument!"
        exit
    fi
else
    echo "Invalid argument!"
    exit
fi

if [ $? != 0 ]; then
    exit
elif [ $TYPE = 1 ]; then
    scrot $FILENAME
elif [ $TYPE = 2 ]; then
    scrot -s $FILENAME
fi

HTML='<img src="data:image/png;base64,'`base64 $FILENAME`'" width="200px"><p>Upload this image?'
echo $HTML | zenity --text-info --html --filename=/dev/stdin
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
rm $FILENAME