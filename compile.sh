#!/usr/bin/env sh

for p in perl mono ffmpeg
do
    if ! (command -v $p >/dev/null)
    then
        echo "You must have Perl, Mono, and FFmpeg installed and available on PATH"
        exit 1
    fi
done

function nofile {
    read -p "Couldn't find a Rhythm Tengoku ROM, please place a Rev. 0 ROM named \"rh-jpn.gba\" in the root of the project."
    check
}

function fail {
    rm -f build/rh-atlus.gba
    read -p "Building failed! (Press enter to recompile!)"

    clear
    check
}

function tools {
    echo "-- Remove Existing Build Directory, if needed"
    rm -rf build
    mkdir build
    echo "-- Made Build Directory --"
    cp rh-jpn.gba build/rh-atlus.gba
}

function check {
    if [ -e "rh-jpn.gba" ];
    then 
        if [ "$(uname -s)" = "Darwin" ]
        then
            md5check="md5"
        else
            md5check="md5sum --status -c"
        fi
        if ($md5check md5sum.txt)
        then
            echo "-- File Passed Checks --"
            tools
        else
            echo "-- File Failed Checks --"
            nofile
        fi
    else
        echo "-- File Failed Checks --"
        nofile
    fi
}

if [ "$(uname -s)" = "Darwin" ]
then
    toolsDir=tools/osx
else
    toolsDir=tools/lin
fi

check

echo "-- Compile Text --"

perl "tools/abcde/abcde.pl" -cm abcde::Atlas "build/rh-atlus.gba" "src/script.txt"

echo "-- Compile Bitmap --"
for file in $(cat src/bitmaps_to_compile.md | sed 1,1d)
do
    $toolsDir/4bmpp -p $file
done

echo "-- Compile Graphics --"
for file in $(cat src/graphics_to_compile.md | sed 1,1d)
do
    mono $toolsDir/DSDecmp.exe -c lz10 $file.bin $file
done

echo "-- Compile Tile Maps --"
for file in $(cat src/tilemaps_to_compile.md | sed 1,1d)
do
    mono $toolsDir/rhcomp.exe $file
done

echo "-- Compile Audio --"

for file in $(cat src/sounds_to_compile.md | sed 1,1d)
do
  echo $file
  ffmpeg -y -i $file.wav -acodec pcm_s8 -ar 13379 -ac 1 -f s8 $file.pcm -loglevel error
done

echo "-- Compile Code --"

if ! ($toolsDir/armips src/main.asm)
then
    fail
fi

rm -f build/rh-atlus.gba
read -p "Building complete! (Press enter to recompile!)"

check
