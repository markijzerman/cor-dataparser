#!/bin/bash
# Script to create Essentia analysis files for every file in dir.
# Must be WAV
# actual analysis happens in analysis.py

shopt -s nullglob
for f in *.wav
do
	echo "Creating Essentia analysis file for - $f"
        python analysis.py $f
done