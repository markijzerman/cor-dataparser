#!/bin/sh
# convert all files in directory to wav

for f in *.m4a *.mp3 *.ogg *.amr *.3gpp
do
	echo "Creating WAV from file - $f"
		ffmpeg -i "$f" ${f%.*}.wav
		rm $f
done