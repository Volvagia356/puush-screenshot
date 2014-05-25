#!/bin/bash
# Screen capture and upload utility for puush
# (C) 2014 Volvagia356
#
# Requires scrot, curl, zenity, and xclip

#Insert your API key here
APIKEY=""

FILENAME=/tmp/`tr -dc A-Za-z0-9 < /dev/urandom | head -c 8`.png

TYPE=`zenity --list --text="Select a screenshot type:" --column="" --column="Type" --hide-header --hide-column=1 1 "Entire desktop" 2 "Single window or rectangular region"`
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
    RESPONSE=`curl -F "k=$APIKEY" -F "z=poop" -F "f=@$FILENAME" https://puush.me/api/up`
    echo $RESPONSE
    if [ $? != 0 ]; then
        zenity --error
    else
        ARGS=(`echo $RESPONSE | tr ',' ' '`)
        echo -n ${ARGS[1]} | xclip -sel clip
        zenity --info --text="URL copied to clipboard."
    fi
fi
rm $FILENAME